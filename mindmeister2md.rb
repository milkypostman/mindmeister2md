#!/usr/bin/env ruby
#--
# mindmeister2md.rb -- Convert MindMeister maps to Markdown
# 
# Copyright (c) 2011 Donald Ephraim Curtis <dcurtis@milkbox.net>
# Copyright (c) 2011 Brett Terpstra
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#++


require 'digest/md5'
require 'uri'
require 'net/http'
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

def auth_valid? (param, secret)
  valparam = param.merge({"method" => "mm.auth.checkToken"})
  valbody = rest_call(api_sig(valparam, secret))
  REXML::Document.new(valbody).elements["rsp"].attributes["stat"] == "ok"
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

class Mindmap
  attr_accessor :key, :title, :modified
  def initialize
    @key = nil
    @title = nil
    @modified = nil
  end

  def initialize(key, title, modified)
    @key = key
    @title = title
    @modified = modified
  end
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
  attr_accessor :key, :title, :link, :note, :image, :children

  def initialize
    @key = nil
    @title = nil
    @note = nil
    @link = nil
    @image = nil
    @children = []
  end

  def initialize(key, title, link, note, image)
    @key = key
    @title = title
    @link = link
    @note = note
    @image = image
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
  STDERR.puts "Opening Safari for authentication."
  STDERR.puts authurl

  `open -a Safari "#{authurl.to_s}"`
  STDERR.puts "Press ENTER after you have successfully authenticated."
  STDIN.gets

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
  dump_config( {"api_key" => nil, "secret" => nil, "list_level" => 2, "indent" => 4 } )
  STDERR.puts "You need to update the configuration file #{$config_file}."
  STDERR.puts
  STDERR.puts "You can apply for an API key here: https://www.mindmeister.com/account/api/"
  STDERR.puts
  exit 1
end

# load our configuration file
config = load_config

# assert we have api_key and secret
if !config.key? "api_key" or !config.key? "secret"
  STDERR.puts "ERROR: api_key or secret not in configuration file!"
  STDERR.puts "Adding keys to configuration; please update accordingly."
  STDERR.puts
  STDERR.puts "You can apply for an API key here: https://www.mindmeister.com/account/api/"
  STDERR.puts
  if !config.key? "api_key"
    config["api_key"] = ""
  end
  if !config.key? "secret"
    config["secret"] = ""
  end
  dump_config( config )
  exit 1
end

# assert that api_key and secret have values
if not config["api_key"]  or not config["secret"]
  STDERR.puts "api_key or secret are missing.  Please update #{$config_file}."
  exit 1
end

param = {"api_key" => config["api_key"]}
secret = config["secret"]

if !config.key? "auth"
  config["auth"] = authenticate(config["api_key"], secret)
  dump_config( config )
end

if !config.key? "indent"
  config["indent"] = 4
  dump_config( config )
end

$indent = config["indent"]

if !config.key? "list_level"
  config["list_level"] = 2
  dump_config( config )
end

$list_level = config["list_level"]

param.update({"auth_token" => config["auth"]["token"]})

if !auth_valid?(param, secret)
  config["auth"] = authenticate(config["api_key"], secret)
  dump_config(config)
  param.update({"auth_token" => config["auth"]["token"]})
end

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: mindmeister2md.rb [options] <map id | map name>"
  opts.on("-o", "--output FILE", "Write output to FILE") do |file|
    options[:outfile] = file
  end
  opts.on("-l", "--list", "List Maps and Exit") do
    options[:list] = true
  end
  opts.on("-i", "--indent <indent>", "Number of spaces for each indent level") do |indent|
    $indent = indent.to_i
  end
  opts.on("-s", "--listlevel <list_level>", "Level at which lists should start") do |listlevel|
    $list_level = listlevel.to_i
  end
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit 1
  end
end

optparse.parse!

menu = []
mapbyid = {}
mapbyname = {}

listparam = param.merge({"method" => "mm.maps.getList"})
listbody = rest_call(api_sig(listparam, secret))

STDERR.puts("fetching maps...")
REXML::Document.new(listbody).elements.each("rsp/maps/map") { |e|
  map = Mindmap.new(e.attributes["id"],
                    e.attributes["title"],
                    e.attributes["modified"])
  menu << map
  mapbyid[map.key] = map
  mapbyname[map.title.downcase] = map
}

maxtitle = mapbyname.keys.max_by{ |k| k.length }.length

# list ONLY
if options[:list]
  menu.each_with_index { |item, idx|
    titlepad = " " * (maxtitle - item.title.length + 2)
    STDOUT.puts "[ #{item.key} ] #{item.title} #{titlepad} ( #{item.modified} )"
  }
  exit
end

# no argument specified
if ARGV.empty?
  STDERR.puts "Available MindMeister Maps"
  STDERR.puts "---"

  # how many digits to consider
  intpad = Math::log10(menu.length).to_i+1
  menu.each_with_index { |item, idx|
    titlepad = " " * (maxtitle - item.title.length + 2)
    
    # just makes the formatting nice
    idxstr = "%#{intpad}d" % (idx+1)
    STDERR.puts "#{idxstr}: #{item.title} #{titlepad} ( #{item.modified} ) [ #{item.key} ]"
  }
  
  sel = 0
  
  while !sel =~ /^\d+$/ || sel.to_i <= 0 || sel.to_i > menu.length
    STDERR.print "Selection: "
    sel = STDIN.gets
  end

  map_id = menu[sel.to_i - 1].key
else
  val = ARGV.join(" ")
  if mapbyid.has_key?(val)
    map_id = mapbyid[val].key
  elsif mapbyname.has_key?(val.downcase)
    map_id = mapbyname[val.downcase].key
  else
    STDERR.puts "Invalid Parameter: No map found."
    exit 1
  end
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
  unless p.elements["image"].elements["url"].nil?
    image = p.elements["image"].elements["url"].text unless p.elements["image"].elements["url"].text.nil?
  end
  i = Idea.new(id, title, link, note, image)
  parent = p.elements["parent"].text
  if parent.nil?
    root = i
  else
    d[parent].children << i
  end

  d[id] = i
end

def print_level (node, level=0, io=STDOUT)
  subindent = level < $list_level ? "" : " " * ((level-$list_level+1)*$indent)
  title = node.title.gsub(/\\n/," ")
  title = node.link.nil? ? title : "[#{title}](#{node.link})"
  title = (node.note.nil?) ? title : "#{title}\n\n#{subindent}#{node.note.gsub(/\s?style="[^"]*?"/,'').gsub(/\\n/, "\n\n#{subindent}")}\n\n"
  title = node.image.nil? ? title : "#{title}\n\n#{subindent}![](#{node.image})\n\n"
  title = title.gsub(/\\r/,' ').gsub(/\\'/,"'").gsub(/\s?style="[^"]*?"/,'').gsub(/([#*])/,'\\\\\1')
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

# outfile if you got em'
io = options[:outfile].nil? ? STDOUT : File.open(options[:outfile], 'w')
print_level(root, 0, io)
