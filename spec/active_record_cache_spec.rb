require 'spec_helper'

describe ActiveRecordCache do
  before :each do
    Rails.cache.clear
    MY_CACHE.clear
    ActiveRecordCache::Tester.destroy_all
    ActiveRecordCache::Test.destroy_all
    ActiveRecordCache::SubTest.destroy_all
    ActiveRecordCache::NoCacheTester.destroy_all
    ActiveRecordCache::TesterNoCacheDefault.destroy_all
  end
  
  let(:test_1){ ActiveRecordCache::Test.create(:name => "test_1") }
  let(:test_2){ ActiveRecordCache::Test.create(:name => "test_2") }
  let(:test_3){ ActiveRecordCache::Test.create(:name => "test_3") }
  let(:subtest_1){ ActiveRecordCache::SubTest.create(:name => "subtest_1") }
  let(:subtest_2){ ActiveRecordCache::SubTest.create(:name => "subtest_2") }
  let(:tester_1){ ActiveRecordCache::Tester.create!(:name => "tester_1", :test => test_1) }
  let(:tester_2){ ActiveRecordCache::Tester.create!(:name => "tester_2", :test => test_1) }
  let(:tester_3){ ActiveRecordCache::Tester.create!(:name => "tester_3", :test => test_2) }
  let(:tester_4){ ActiveRecordCache::Tester.create!(:name => "tester_4", :test => test_2) }
  let(:no_cache_tester_1){ ActiveRecordCache::NoCacheTester.create!(:name => "no_cache_tester_1") }
  let(:no_cache_tester_2){ ActiveRecordCache::NoCacheTester.create!(:name => "no_cache_tester_2") }
  let(:no_cache_default_tester_1){ ActiveRecordCache::TesterNoCacheDefault.create!(:name => "no_cache_default_tester_1") }
  let(:no_cache_default_tester_2){ ActiveRecordCache::TesterNoCacheDefault.create!(:name => "no_cache_default_tester_2") }
  
  it "should have a cache that defaults to Rails.cache" do
    ActiveRecordCache.cache.should == Rails.cache
    begin
      my_cache = ActiveSupport::Cache::MemoryStore.new
      ActiveRecordCache.cache = my_cache
      ActiveRecordCache.cache.should == my_cache
    ensure
      ActiveRecordCache.cache = Rails.cache
    end
  end
  
  context "injecting behavior into a model" do
    it "should be able to add caching to a model" do
      ActiveRecordCache::Tester.record_cache.cache.should == Rails.cache
    end
    
    it "should be able to specify the cache to use" do
      ActiveRecordCache::Test.record_cache.cache.should == MY_CACHE
    end
    
    it "should be able to specify the number of seconds until entries expire" do
      ActiveRecordCache::Tester.record_cache.expires_in.should == nil
      ActiveRecordCache::Test.record_cache.expires_in.should == 30
    end
    
    it "should have a scope to find from the database" do
      scope = ActiveRecordCache::Tester.from_database
      scope.should be_a(ActiveRecord::Relation)
      scope.query_from_cache_value.should == false
    end
    
    it "should have a scope to find from the cache" do
      scope = ActiveRecordCache::TesterNoCacheDefault.from_cache
      scope.should be_a(ActiveRecord::Relation)
      scope.query_from_cache_value.should == true
    end
    
    it "should be able to expire a cache entry" do
      key = ActiveRecordCache::Tester.record_cache.cache_key(1)
      Rails.cache.write(key, "boo")
      Rails.cache.read(key).should == "boo"
      ActiveRecordCache::Tester.expire_cache_entry(1)
      Rails.cache.exist?(key).should == false
    end
    
    it "should expire an entry when a record is destroyed" do
      key = ActiveRecordCache::Tester.record_cache.cache_key(tester_1.id)
      Rails.cache.write(key, "boo")
      Rails.cache.exist?(key).should == true
      tester_1.destroy
      Rails.cache.exist?(key).should == false
    end
    
    it "should expire an entry when a record is updated" do
      key = ActiveRecordCache::Tester.record_cache.cache_key(tester_1.id)
      Rails.cache.write(key, "boo")
      Rails.cache.exist?(key).should == true
      tester_1.update_attribute(:name, "new value")
      Rails.cache.exist?(key).should == false
    end
    
    it "should inherit caching" do
      ActiveRecordCache::SubTest.record_cache.should == ActiveRecordCache::Test.record_cache
    end
  end
  
  context "default behavior" do
    it "should not use the cache by default" do
      ActiveRecordCache::TesterNoCacheDefault.find(no_cache_default_tester_1.id).should == no_cache_default_tester_1
      Rails.cache.should be_empty
    end
    
    it "should use the cache if the default is set to true" do
      ActiveRecordCache::Tester.find(tester_1.id).should == tester_1
      Rails.cache.size.should == 1
    end
    
    it "should be able to set the defaults in a block" do
      ActiveRecordCache::Tester.record_cache.default.should == true
      ActiveRecordCache::Test.record_cache.default.should == true
      ActiveRecordCache::TesterNoCacheDefault.record_cache.default.should == false
      
      ActiveRecordCache.enable_by_default_on(ActiveRecordCache::Tester => false, "ActiveRecordCache::TesterNoCacheDefault" => true) do
        ActiveRecordCache::Tester.record_cache.default.should == false
        ActiveRecordCache::Test.record_cache.default.should == true
        ActiveRecordCache::TesterNoCacheDefault.record_cache.default.should == true
        
        ActiveRecordCache.enable_by_default_on(ActiveRecordCache::Test => false, "ActiveRecordCache::Tester" => true) do
          ActiveRecordCache::Tester.record_cache.default.should == true
          ActiveRecordCache::Test.record_cache.default.should == false
          ActiveRecordCache::TesterNoCacheDefault.record_cache.default.should == true
        end
        
        ActiveRecordCache::Tester.record_cache.default.should == false
        ActiveRecordCache::Test.record_cache.default.should == true
        ActiveRecordCache::TesterNoCacheDefault.record_cache.default.should == true
      end
      
      ActiveRecordCache::Tester.record_cache.default.should == true
      ActiveRecordCache::Test.record_cache.default.should == true
      ActiveRecordCache::TesterNoCacheDefault.record_cache.default.should == false
    end
  end
  
  context "caching" do
    before :each do
      test_1
      test_2
      test_3
      subtest_1
      subtest_2
      tester_1
      tester_2
      tester_3
      tester_4
      no_cache_tester_1
      no_cache_tester_2
    end
    
    it "should lazy load a single record into the cache" do
      ActiveRecordCache::Tester.find(tester_1.id).should == tester_1
      ActiveRecordCache::Tester.connection.should_not_receive(:select)
      ActiveRecordCache::Tester.find(tester_1.id).should == tester_1
      ActiveRecordCache::Tester.find(tester_1.id.to_s).should == tester_1
      ActiveRecordCache::Tester.find_by_id(tester_1.id).should == tester_1
      ActiveRecordCache::Tester.where(:id => tester_1.id).should == [tester_1]
      ActiveRecordCache::Tester.where("id" => tester_1.id.to_s).should == [tester_1]
      c = ActiveRecordCache::Tester.connection
      sql = "#{c.quote_table_name(ActiveRecordCache::Tester.table_name)}.#{c.quote_column_name('id')} = #{tester_1.id}"
      ActiveRecordCache::Tester.where(sql).should == [tester_1]
    end
    
    it "should lazy load multiple records into the cache" do
      ActiveRecordCache::Tester.find(tester_1.id, tester_2.id).sort_by_field(:name).should == [tester_1, tester_2]
      ActiveRecordCache::Tester.connection.should_not_receive(:select)
      ActiveRecordCache::Tester.find(tester_1.id, tester_2.id).sort_by_field(:name).should == [tester_1, tester_2]
      ActiveRecordCache::Tester.find_all_by_id([tester_1.id, tester_2.id]).sort_by_field(:name).should == [tester_1, tester_2]
      ActiveRecordCache::Tester.where(:id => [tester_1.id, tester_2.id]).should == [tester_1, tester_2]
      ActiveRecordCache::Tester.where("id" => [tester_1.id.to_s, tester_2.id.to_s]).should == [tester_1, tester_2]
      c = ActiveRecordCache::Tester.connection
      sql = "#{c.quote_table_name(ActiveRecordCache::Tester.table_name)}.#{c.quote_column_name('id')} IN (#{tester_1.id}, #{tester_2.id})"
      ActiveRecordCache::Tester.where(sql).should == [tester_1, tester_2]
    end
    
    it "should only load records not already in the cache from the database" do
      ActiveRecordCache::Tester.find(tester_1.id).should == tester_1
      key = ActiveRecordCache::Tester.record_cache.cache_key(tester_1.id)
      first_cache_entry = Rails.cache[key]
      ActiveRecordCache::Tester.find(tester_1.id, tester_2.id).sort_by_field(:name).should == [tester_1, tester_2]
      Rails.cache[key].object_id.should == first_cache_entry.object_id
      Rails.cache.size.should == 2
    end
    
    it "should cache when limit is set" do
      found = ActiveRecordCache::Tester.where(:id => [tester_1.id, tester_2.id]).limit(1).first
      [tester_1, tester_2].should include(found)
      Rails.cache.size.should == 2
    end
    
    it "should cache when ordering is by a single column" do
      found = ActiveRecordCache::Tester.where(:id => [tester_1.id, tester_2.id]).order(:name).should == [tester_1, tester_2]
      Rails.cache.size.should == 2
    end
    
    it "should cache when ordering is by a single column with a direction" do
      found = ActiveRecordCache::Tester.where(:id => [tester_1.id, tester_2.id]).order("name DESC").should == [tester_2, tester_1]
      Rails.cache.size.should == 2
    end
    
    it "should cache when loading belongs_to associations" do
      records = ActiveRecordCache::Tester.where(:id => [tester_1.id, tester_2.id, tester_3.id]).order(:name).preload(:test)
      records.should == [tester_1, tester_2, tester_3]
      ActiveRecordCache::Test.connection.should_not_receive(:select)
      records.all?{|r| r.test_association_loaded? }.should == true
      ActiveRecordCache::Test.find(tester_1.test_id).should == test_1
      ActiveRecordCache::Test.find(tester_2.test_id).should == test_1
      ActiveRecordCache::Test.find(tester_3.test_id).should == test_2
    end
    
    it "should preload specified associations" do
      tester_1.no_cache_testers.create(:name => "relation_1")
      tester_1.no_cache_testers.create(:name => "relation_2")
      record = ActiveRecordCache::Tester.find(tester_1.id)
      record.no_cache_testers.loaded?.should == true
    end
    
    it "should cache when using polymorphic tables" do
      ActiveRecordCache::SubTest.find(subtest_1.id).should == subtest_1
      ActiveRecordCache::SubTest.connection.should_not_receive(:select)
      ActiveRecordCache::SubTest.where(:id => subtest_1.id).should == [subtest_1]
    end
    
    it "should not cache when force loading from the database" do
      ActiveRecordCache::Tester.from_database.where(:id => tester_1.id).should == [tester_1]
      Rails.cache.should be_empty
    end
    
    it "should not cache when there are multiple elements to a where clause hash" do
      ActiveRecordCache::Tester.from_database.where(:id => tester_1.id, :name => "tester_1").should == [tester_1]
      ActiveRecordCache::Tester.from_database.where(:id => tester_1.id).where(:name => "tester_1").should == [tester_1]
      Rails.cache.should be_empty
    end
    
    it "should not cache when there are mulitple clauses in a sql string where clause" do
      c = ActiveRecordCache::Tester.connection
      sql = "#{c.quote_table_name(ActiveRecordCache::Tester.table_name)}.#{c.quote_column_name('id')} = #{tester_1.id} AND name = 'tester_1'"
      ActiveRecordCache::Tester.from_database.where(sql).should == [tester_1]
      Rails.cache.should be_empty
    end
    
    it "should not cache when ordering is more complex than a single column with a direction" do
      ActiveRecordCache::Tester.where(:id => [tester_1.id, tester_2.id]).order(:name).order(:id).should == [tester_1, tester_2]
      ActiveRecordCache::Tester.where(:id => [tester_1.id, tester_2.id]).order("name, id").should == [tester_1, tester_2]
      Rails.cache.should be_empty
    end
    
    it "should not cache with offset is set" do
      ActiveRecordCache::Tester.where(:id => [tester_1.id, tester_2.id]).order(:name).offset(1).should == [tester_2]
      Rails.cache.should be_empty
    end
    
    it "should not cache when joins are used" do
      ActiveRecordCache::Tester.where(:id => tester_1.id).joins(:test).should == [tester_1]
      Rails.cache.should be_empty
    end
    
    it "should not cache when select is used" do
      ActiveRecordCache::Tester.where(:id => tester_1.id).select(:id).should == [tester_1]
      Rails.cache.should be_empty
    end
    
    it "should not cache when from is used" do
      ActiveRecordCache::Tester.where(:id => tester_1.id).from(ActiveRecordCache::Tester.table_name).should == [tester_1]
      Rails.cache.should be_empty
    end
    
    it "should not cache when grouping is used" do
      ActiveRecordCache::Tester.where(:id => tester_1.id).group(:name).should == [tester_1]
      Rails.cache.should be_empty
    end
    
    it "should not cache when having is used" do
      ActiveRecordCache::Tester.where(:id => tester_1.id).group(:name).having(:name => "tester_1").should == [tester_1]
      Rails.cache.should be_empty
    end
  end
end
