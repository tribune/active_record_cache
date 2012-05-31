require 'spec_helper'

describe ActiveRecordCache::RelationExtension do
  context "forcing database queries" do
    let(:relation){ ActiveRecordCache::Tester.unscoped }

    it "should add an attribute indicating if the relation should always be read from the database" do
      relation.query_from_cache_value.should == nil
      relation.from_database.query_from_cache_value.should == false
      relation.from_cache.query_from_cache_value.should == true
    end
    
    it "should merge the force database read value when merging with another relation" do
      relation.from_database.where(:id => 1).query_from_cache_value.should == false
      relation.where(:id => 1).from_cache.query_from_cache_value.should == true
    end
  end
  
  context "using the cache" do
    let(:tester_1){ ActiveRecordCache::Tester.create!(:name => "tester_1") }
    
    before :each do
      tester_1
    end
    
    it "should not use the cache if the relation is already loaded" do
      relation = ActiveRecordCache::Tester.where(:id => tester_1.id)
      relation.to_a
      relation.loaded?.should == true
      Rails.cache.size.should == 1
      Rails.cache.clear
      relation.to_a
      Rails.cache.should be_empty
    end
    
    it "should not get records from the cache when the class does not support caching" do
      relation = ActiveRecordCache::NoCacheTester.scoped
      relation.to_a
      Rails.cache.should be_empty
    end
    
    it "should not get records from the cache when it is not a cacheable query" do
      relation = ActiveRecordCache::Tester.where(:id => tester_1.id, :name => tester_1.name)
      relation.to_a
      Rails.cache.should be_empty
    end
    
    it "should not get records from the cache when the query is forcing a database read" do
      relation = ActiveRecordCache::Tester.where(:id => tester_1.id).from_database
      relation.to_a
      Rails.cache.should be_empty
    end
    
    it "should get records from the cache when the class supports caching, it is a cacheable query, and the query is not forcing a database read" do
      relation = ActiveRecordCache::Tester.where(:id => tester_1.id)
      relation.to_a
      Rails.cache.size.should == 1
    end
  end
end
