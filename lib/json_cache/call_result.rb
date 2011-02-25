module JsonCache
  class CallResult
    include Mongoid::Document
    include Mongoid::Timestamps
    field "_query_params", :type => Hash
    field "_query_name"
  end
end