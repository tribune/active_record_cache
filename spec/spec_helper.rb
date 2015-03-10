require 'rubygems'
require 'bundler'
Bundler.setup(:default, :development)
require 'sqlite3'
require 'active_record'
puts "Testing against #{ActiveRecord::VERSION::STRING} (See the Gemfile for how to test different versions)"

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
  end
rescue LoadError
  # simplecov not installed
end

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'active_record_cache'))

MY_CACHE = ActiveSupport::Cache::MemoryStore.new

# Upgrade warning: defining 'Rails' breaks ActiveRecord 4.
module Rails
  def self.cache
    unless defined?(@cache)
      @cache = ActiveSupport::Cache::MemoryStore.new
    end
    @cache
  end
end


ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")



module ActiveRecordCache
  class Tester < ActiveRecord::Base
    include ActiveRecordCache
    use_record_cache :preload => :no_cache_testers, :default => true
    
    belongs_to :test
    has_many :no_cache_testers
    
    def self.create_table
      connection.create_table(table_name) do |t|
        t.string :name
        t.integer :test_id
      end
    end
    
    def test_association_loaded?
      if respond_to?(:association)
        association(:test).loaded?
      else
        self.loaded_test?
      end
    end
  end
  
  class Test < ActiveRecord::Base
    include ActiveRecordCache
    use_record_cache :cache => MY_CACHE, :expires_in => 30, :default => true
    
    def self.create_table
      connection.create_table(table_name) do |t|
        t.string :name
        t.string :type
      end
    end
  end
  
  class SubTest < Test
  end
  
  class TesterNoCacheDefault < ActiveRecord::Base
    include ActiveRecordCache
    use_record_cache :preload => :no_cache_testers
    
    def self.create_table
      connection.create_table(table_name) do |t|
        t.string :name
      end
    end
  end
  
  class NoCacheTester < ActiveRecord::Base
    
    def self.create_table
      connection.create_table(table_name) do |t|
        t.string :name
        t.integer :tester_id
      end
    end
  end
  
  # Used for testing with MemoryStore.
  module CachePeek
    def size
      @data.size
    end
    
    def empty?
      size == 0
    end
    
    def [](key)
      @data[key]
    end
  end
  
  ActiveSupport::Cache::MemoryStore.send(:include, CachePeek)
end

ActiveRecordCache::Tester.create_table
ActiveRecordCache::Test.create_table
ActiveRecordCache::NoCacheTester.create_table
ActiveRecordCache::TesterNoCacheDefault.create_table
