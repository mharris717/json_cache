module JsonCache
  module Processing
    fattr(:processors) { {} }
    def processor(n,&b)
      self.processors[n.to_sym] = b
    end
    def process!(n)
      b = self.processors[n.to_sym]
      type_class.unprocessed(n).each { |x| b[x] }
    end
  end
  class MethodCache
    include FromHash
    include Processing
    attr_accessor :name, :call_blk, :class_name, :class_blk
    def call_blk(&b)
      if block_given?
        @call_blk = b
      else
        @call_blk
      end
    end
    def class_blk(&b)
      if block_given?
        @class_blk = b
      else
        @class_blk
      end
    end
    def ensure_class_exists
      eval class_name
    rescue
      return make_class
    end
    def make_class
      b = class_blk || lambda { |x| }
      cls = Class.new(JsonCache::CallResult,&b)
      Object.const_set(class_name,cls)
      cls
    end
    fattr(:type_class) do
      if class_name
        ensure_class_exists
      else
        JsonCache::CallResult
      end
    end
    def get_existing(ops)
      a = type_class.where('_json_cache_internal.query_params' => ops)
      f = a.first
      if !f
        nil
      elsif f['_json_cache_internal']['from_array']
        a.to_a
      else
        f
      end
    end
    def need?(ops)
      !get_existing(ops)
    end
    def create_from_raw(raw,ops,from_array)
      h = {:query_params => ops, :name => name, :from_array => from_array}
      cr_hash = raw.merge('_json_cache_internal' => h)
      type_class.create!(cr_hash)
    end
    def get_fresh(ops)
      res = call_blk[ops]
      if res.kind_of?(Array)
        res.map { |x| create_from_raw(x,ops,true) }
      else
        create_from_raw(res,ops,false)
      end
    end
    def get(ops)
      if need?(ops)
        get_fresh(ops)
      else
        get_existing(ops)
      end
    end
    def all
      JsonCache::CallResult.where('_json_cache_internal.name' => name)
    end
  end
  
  
end