module JsonCache
  class CacheManager
    include FromHash
    fattr(:caches) { {} }
    def reg(name,ops={})
      res = self.caches[name.to_sym] = JsonCache::MethodCache.new(ops.merge(:name => name))
      yield(res) if block_given?
    end 
    def reg_simple(name,&b)
      reg(name) do |c|
        c.call_blk = b
      end
    end
    def get_cache(name)
      caches[name.to_sym] || (raise "no cache #{name}")
    end
    def method_missing(sym,*args,&b)
      if args.empty?
        get_cache(sym)
      else
        get_cache(sym).send(:get,*args,&b)
      end
    end
  end
end