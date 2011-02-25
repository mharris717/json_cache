require 'mharris_ext'
require 'mongoid'

Mongoid.configure do |config|
  name = "json_cache_dev"
  host = "mydesk"
  config.master = Mongo::Connection.new(host).db(name)
end

%w(call_result method_cache cache_manager).each do |f|
  require File.dirname(__FILE__) + "/json_cache/#{f}"
end
