module JsonCache
  class CallResult
    include Mongoid::Document
    include Mongoid::Timestamps
    field "_json_cache_internal", :type => Hash
    field "_query_params", :type => Hash
    field "_query_name"
    def self.processed(name)
      where("_json_cache_internal.processed.#{name}" => true)
    end
    def self.unprocessed(name)
      where("_json_cache_internal.processed.#{name}".to_sym.ne => true)
    end
  end
end