require 'mharris_ext'
require 'mongoid'


%w(call_result method_cache cache_manager).each do |f|
  require File.dirname(__FILE__) + "/json_cache/#{f}"
end

module JsonCache
  def self.manager
    @manager ||= JsonCache::CacheManager.new
  end
  def self.method_missing(sym,*args,&b)
    manager.send(sym,*args,&b)
  end
end
