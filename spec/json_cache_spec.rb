require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

if false
  class Thing < JsonCache::CallResult
  end
  
  class Kernel::Thing < JsonCache::CallResult
  end
  JsonCache::CallResult.all.each { |x| x.destroy }
  raise 'foo'
end

describe "JsonCache" do
  describe 'method cache' do
    def mc; @mc; end
    def mc2; @mc2; end
    before do
      JsonCache::CallResult.delete_all
      @blk = lambda do |num|
        {'num' => num*2}
      end
      @mc = JsonCache::MethodCache.new(:name => 'test', :call_blk => @blk)
    end
    after do
      JsonCache::CallResult.delete_all
    end
    it 'get first' do
      mc.get(2)['num'].should == 4
    end
    it 'should need' do
      mc.should be_need(2)
    end
    it 'initial get should return call result' do
      mc.get(2).should be_kind_of(JsonCache::CallResult)
    end
    
    describe 'already got' do
      before do
        mc.get(2)
      end
      it 'should save a call result' do
        JsonCache::CallResult.where('_json_cache_internal.query_params' => 2).count.should == 1
      end
      it 'call result should have results' do
        JsonCache::CallResult.where('_json_cache_internal.query_params' => 2).first.num.should == 4
      end
      it 'should not need' do
        mc.should_not be_need(2)
      end
      it 'should need different query' do
        mc.should be_need(3)
      end
      it 'should get result for diff query' do
        mc.get(3)['num'].should == 6
      end
      it 'get again' do
        dont_allow(mc).get_fresh(anything)
        mc.get(2)
      end
    end
    
    describe 'call blk returns array' do
      before do
        mc.call_blk = lambda do |num|
          [num,num*2].map { |x| {'num' => x} }
        end
      end
      it 'should return 2 CallResults' do
        mc.get(2).map { |x| x.class }.should == [JsonCache::CallResult,JsonCache::CallResult]
      end
      it '2nd get should result 2 CallResults' do
        mc.get(2)
        mc.get(2).should be_kind_of(Array)
      end
    end
    
    describe 'class block' do
      before do
        mc.class_name = 'Thing'
        mc.class_blk = lambda do |x|
          def num_plus(n)
            num + n
          end
        end
      end
      
      it 'smoke' do
        mc.get(2).num.should == 4
      end
      it 'type_class' do
        mc.type_class.should == Thing
      end
      it 'call blk method' do
        mc.get(2).num_plus(3).should == 7
      end
      it 'obj class' do
        mc.get(2).should be_kind_of(Thing)
      end
    end
    
    describe 'multiple caches, one with own class' do
      before do
        @mc2 = JsonCache::MethodCache.new(:name => 'test2', :call_blk => @blk)
        mc2.class_name = 'Thing'
        mc2.class_blk = lambda do |x|
          def num_plus(n)
            num + n
          end
        end
      end
      
      describe 'each has been called' do
        before do
          mc.get(2)
          mc2.get(3)
        end
        it 'should be 1 thing' do
          Thing.count.should == 1
          mc2.all.count.should == 1
        end
        it 'should be 2 call results' do
          JsonCache::CallResult.count.should == 2
          mc.all.count.should == 1
        end
      end
    end

  
    it 'manager ugly test all' do
      m = JsonCache::CacheManager.new
      m.reg :nums, :class_name => 'Num' do |c|
        c.call_blk do |num|
          {'num' => num * 2}
        end
        c.class_blk do |unused|
          def num_plus(n)
            num + n
          end
        end
      end
      m.nums(2).num.should == 4
      m.nums(2).num_plus(3).should == 7
      m.get_cache(:nums).all.count.should == 1
    end
    
    it 'manager ugly test all simple' do
      m = JsonCache::CacheManager.new
      m.reg_simple :nums do |num|
        {'num' => num * 2}
      end
      
      m.get_cache(:nums).type_class.should == JsonCache::CallResult
      m.nums(2).num.should == 4
      
      m.nums(2).class.should == JsonCache::CallResult
      m.nums(2).should_not be_respond_to(:num_plus)
      lambda { m.nums(2).num_plus(3) }.should raise_error
      
      m.get_cache(:nums).all.count.should == 1
    end
    
    describe 'processing' do
      before do
        mc.class_name = 'Item'
        @process_list = []
        mc.processor :real do |obj|
          @process_list << obj
        end
        mc.get(2)
      end
      it 'has count' do
        Item.count.should == 1
      end
      it 'processed counts' do
        Item.unprocessed(:real).count.should == 1
        Item.processed(:real).count.should == 0
      end
      it 'process smoke' do
        mc.process!(:real)
        @process_list.map { |x| x.num }.should == [4]
      end
    end
  
  end
  
end
