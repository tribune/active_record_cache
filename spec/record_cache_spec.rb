require 'spec_helper'

describe ActiveRecordCache::RecordCache do
  let(:cache){ ActiveSupport::Cache::MemoryStore.new(:expires_in => 60) }
  let(:record_cache){ ActiveRecordCache::RecordCache.new(ActiveRecordCache::Tester, :cache => cache, :expires_in => 120) }
  let(:tester_1){ ActiveRecordCache::Tester.create!(:name => "tester_1") }
  let(:tester_2){ ActiveRecordCache::Tester.create!(:name => "tester_2") }
  let(:tester_3){ ActiveRecordCache::Tester.create!(:name => "tester_3") }
  
  before :each do
    Rails.cache.clear
    ActiveRecordCache::Tester.destroy_all
    tester_1
    tester_2
    tester_3
  end
  
  it "should have an underlying cache" do
    record_cache.cache.should == cache
  end
  
  it "should have an expires_in time" do
    record_cache.expires_in.should == 120
  end
  
  it "should default the expires_in time to the cache's default" do
    record_cache = ActiveRecordCache::RecordCache.new(ActiveRecordCache::Tester, :cache => cache)
    record_cache.expires_in.should == 60
  end
  
  it "should read a single value" do
    record_cache[tester_1.id].should == tester_1
  end
  
  it "should read a single value using the read method" do
    record_cache.read(tester_1.id).should == [tester_1]
  end
  
  it "should read multiple values" do
    record_cache.read([tester_1.id, tester_2.id]).sort_by_field(:name).should == [tester_1, tester_2]
  end
  
  it "should get a cache key for a record id" do
    record_cache.cache_key(1).should == "active_record_cache/testers/1"
  end
  
  it "should expire an id from the cache" do
    record_cache[tester_1.id]
    cache.size.should == 1
    record_cache.expire(tester_1.id)
    cache.should be_empty
  end
end
