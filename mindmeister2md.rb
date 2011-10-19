#!/usr/bin/env ruby

require 'digest/md5'
require 'uri'
require 'net/http'
require 'net/https'
require 'yaml'
require 'rexml/document'
require 'optparse'

$host = "www.mindmeister.com"

$config_file = File.expand_path("~/.mindmeister2md")

def load_config
  File.open($config_file) { |yf| YAML::load(yf) }
end

def dump_config (config)
  File.open($config_file, 'w') { |yf| YAML::dump(config, yf) }
end

def rest_call(param)
  url = URI::HTTP.build({:host => $host, :path => "/services/rest", :query => param})
  Net::HTTP.get_response(url).body
end  

def join_param (param)
  URI.escape(
  param.sort.map { |key, val|
    "#{key}=#{val}"
  }.join("&"))
end

def api_sig (param, secret)
  URI.escape(join_param(param) + 
             "&api_sig=" + 
             Digest::MD5.hexdigest(secret + param.sort.join))
end

class String
  # Removes HTML tags from a string. Allows you to specify some tags to be kept.
  def strip_html( allowed = [] )    
    re = if allowed.any?
      Regexp.new(
        %(<(?!(\\s|\\/)*(#{
          allowed.map {|tag| Regexp.escape( tag )}.join( "|" )
        })( |>|\\/|'|"|<|\\s*\\z))[^>]*(>+|\\s*\\z)),
        Regexp::IGNORECASE | Regexp::MULTILINE
      )
    else
      /<[^>]*(>+|\s*\z)/m
    end
    gsub(re,'')
  end
end

class Idea
  attr_accessor :key, :title, :link, :note, :children

  def initialize
    @key = nil
    @title = nil
    @note = nil
    @link = nil
    @children = []
  end

  def initialize(key, title, link, note)
    @key = key
    @title = title
    @link = link
    @note = note
    @children = []
  end
end

def authenticate (api_key, secret)
  # first we have to get the frob
  froparam = {"api_key" => api_key, "method" => "mm.auth.getFrob"}
  frobbody = rest_call(api_sig(froparam, secret))
  frob = REXML::Document.new(frobbody).elements["rsp/frob"].text

  # next the user has to authenticate this API key
  authparam = {"api_key" => api_key, "perms" => "read", "frob" => frob}
  authurl = URI::HTTPS.build({:host => $host, :path => "/services/auth", :query => api_sig(authparam, secret)})
  puts "Opening Safari for authentication."
  puts authurl

  `open -a Safari "#{authurl.to_s}"`
  puts "Press ENTER after you have successfully authenticated."
  gets

  # now we actually get the auth data
  authparam = {"api_key" => api_key, "method" => "mm.auth.getToken", "frob" => frob}
  authbody = rest_call(api_sig(authparam, secret))

  auth = REXML::Document.new(authbody).elements["rsp/auth"]

  {
    "token" => auth.elements["token"].text,
    "username" => auth.elements["user"].attributes["username"],
    "userid" => auth.elements["user"].attributes["id"],
    "fullname" => auth.elements["user"].attributes["fullname"],
    "email" => auth.elements["user"].attributes["email"],
  }
end

# if the configuration file doesn't exist, create it with default values
if !File.exists? $config_file
  dump_config( {"api_key" => "", "secret" => ""} )
  puts "You need to update the configuration file #{$config_file}."
  puts
  puts "You can apply for an API key here: https://www.mindmeister.com/account/api/"
  puts
  Process.exit(-1)
end

# load our configuration file
config = load_config

# assert we have api_key and secret
if !config.key? "api_key" or !config.key? "secret"
  puts "ERROR: api_key or secret not in configuration file!"
  puts "Adding keys to configuration; please update accordingly."
  puts
  puts "You can apply for an API key here: https://www.mindmeister.com/account/api/"
  puts
  if !config.key? "api_key"
    config["api_key"] = ""
  end
  if !config.key? "secret"
    config["secret"] = ""
  end
  dump_config( config )
  Process.exit(-1)
end

# assert that api_key and secret have values
if config["api_key"] == "" or config["secret"] == ""
  puts "api_key or secret are missing.  Please update #{$config_file}."
  Process.exit(-1)
end

param = {"api_key" => config["api_key"]}
secret = config["secret"]

if !config.key? "auth"
  config["auth"] = authenticate(config["api_key"], secret)
  dump_config( config )
end

if !config.key? "indent"
  config["indent"] = 2
  dump_config( config )
end

$indent = config["indent"]

if !config.key? "list_level"
  config["list_level"] = 2
  dump_config( config )
end

$list_level = config["list_level"]

auth = config["auth"]
param.update({"auth_token" => auth["token"]})

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: mindmeister2md.rb [options] [mapid]"
  opts.on("-o", "--output FILE", "Write output to FILE") do |file|
    options[:outfile] = file
  end
   opts.on( '-h', '--help', 'Display this screen' ) do
     puts opts
     exit
   end
end

optparse.parse!

if ARGV.empty?
  STDERR.puts "Available MindMeister Maps"
  STDERR.puts "---"

  listparam = param.merge({"method" => "mm.maps.getList"})
  listbody = rest_call(api_sig(listparam, secret))

  # puts listbody
  menu = []
  idx = 1

  REXML::Document.new(listbody).elements.each("rsp/maps/map") { |e|
    mid = e.attributes["id"]
    mtitle = e.attributes["title"]
    STDERR.puts "#{idx}: #{mtitle}    [ #{mid} ]"
    menu << mid
    idx += 1
  }

  sel = 0
  
  while !sel =~ /^\d+$/ || sel.to_i <= 0 || sel.to_i > menu.length
    STDERR.print "Selection: "
    sel = STDIN.gets
  end

  map_id = menu[sel.to_i - 1]
else
  map_id = ARGV[0]
end

d = Hash.new()

mapparam = param.merge({"method" => "mm.maps.getMap", "map_id" => map_id})
mapbody = rest_call(api_sig(mapparam, secret))

root = nil

doc, posts = REXML::Document.new(mapbody)
doc.elements.each("rsp/ideas/idea") do |p|
  id = p.elements["id"].text
  title = p.elements["title"].text
  link = p.elements["link"].text unless p.elements["link"].text.nil?
  note = p.elements["note"].text.strip_html(['a']) unless p.elements["note"].text.nil?
  i = Idea.new(id, title, link, note)
  parent = p.elements["parent"].text
  if parent.nil?
    root = i
  else
    d[parent].children << i
  end

  d[id] = i
end

def print_level (node, level=0, io=STDOUT)
  title = node.title
  title = node.link.nil? ? title : "[#{title}](#{node.link})"
  title = (node.note.nil? || spaces == 0) ? title : "#{title}\n\n    #{node.note.gsub(/\s?style="[^"]*?"/,'')}\n\n"
  title = title.gsub(/\\r?/,'').gsub(/\s?style="[^"]*?"/,'').gsub(/([#*])/,'\\\\\1')
  if level < $list_level
    io.print "#" * (level+1)
    io.puts " #{title}\n\n"
  else
    io.print " " * ((level-$list_level)*$indent)
    io.puts "* #{title}"
  end
  node.children.each { |n|
    print_level(n, level + 1, io)
  }
  if level <= $list_level-1
    io.print level == $list_level - 1 ? "\n\n" : "\n"
  end
end

io = options[:outfile].nil? ? STDOUT : File.open(options[:outfile], 'w')
print_level(root, 0, io)

