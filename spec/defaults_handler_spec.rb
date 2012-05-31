require 'spec_helper'

describe ActiveRecordCache::DefaultsHandler do
  it "should set the defaults for classes withing a rack request" do
    ActiveRecordCache::Tester.record_cache.default.should == true
    ActiveRecordCache::Test.record_cache.default.should == true
    ActiveRecordCache::TesterNoCacheDefault.record_cache.default.should == false
    app = lambda{|env| [200, {:tester => ActiveRecordCache::Tester.record_cache.default, :test => ActiveRecordCache::Test.record_cache.default, :no_cache => ActiveRecordCache::TesterNoCacheDefault.record_cache.default}, env.inspect]}
    handler = ActiveRecordCache::DefaultsHandler.new(app, ActiveRecordCache::Tester => false, "ActiveRecordCache::TesterNoCacheDefault" => true)
    env = {"hello" => "world"}
    handler.call(env).should == [200, {:tester => false, :test => true, :no_cache => true}, env.inspect]
  end
end
