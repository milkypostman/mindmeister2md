#!/usr/bin/env ruby

require 'digest/md5'
require 'uri'
require 'net/http'
require 'yaml'
require 'rexml/document'

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

class Idea
  attr_accessor :key, :title, :children

  def initialize
    @key = nil
    @title = nil
    @children = []
  end

  def initialize(key, title)
    @key = key
    @title = title
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
  authurl = URI::HTTP.build({:host => $host, :path => "/services/auth", :query => api_sig(authparam, secret)})
  puts "Opening Safari for authentication."
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
  Process.exit -1
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
  Process.exit -1
end

# assert that api_key and secret have values
if config["api_key"] == "" or config["secret"] == ""
  puts "api_key or secret are missing.  Please update #{$config_file}."
  Process.exit -1
end

param = {"api_key" => config["api_key"]}
secret = config["secret"]

if !config.key? "auth"
  config["auth"] = authenticate(config["api_key"], secret)
  dump_config( config )
end

auth = config["auth"]
param.update({"auth_token" => auth["token"]})

if ARGV.empty?
  puts "Listing MindMeister Maps"
  puts "---"

  listparam = param.merge({"method" => "mm.maps.getList"})
  listbody = rest_call(api_sig(listparam, secret))

  # puts listbody

  REXML::Document.new(listbody).elements.each("rsp/maps/map") { |e|
    mid = e.attributes["id"]
    mtitle = e.attributes["title"]
    puts "#{mid} : #{mtitle}"
  }

else
  d = Hash.new()

  mapparam = param.merge({"method" => "mm.maps.getMap", "map_id" => ARGV[0]})
  mapbody = rest_call(api_sig(mapparam, secret))

  root = nil

  doc, posts = REXML::Document.new(mapbody)
  doc.elements.each("rsp/ideas/idea") do |p|
    id = p.elements["id"].text
    title = p.elements["title"].text
    i = Idea.new(id, title)
    parent = p.elements["parent"].text
    if parent.nil?
      root = i
    else
      d[parent].children << i
    end

    d[id] = i
  end

  def print_level ( node, spaces)
    puts "#{spaces}* #{node.title}"
    node.children.each { |n|
      print_level(n, spaces + "    ")
    }
  end


  print_level(root, "")

end



