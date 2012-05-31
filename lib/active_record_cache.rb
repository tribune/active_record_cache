require 'active_record'
require 'active_support/all'
require 'sort_by_field'

module ActiveRecordCache
  extend ActiveSupport::Concern
  
  autoload :DefaultsHandler, File.expand_path("../active_record_cache/defaults_handler.rb", __FILE__)
  autoload :RecordCache, File.expand_path("../active_record_cache/record_cache.rb", __FILE__)
  autoload :RelationExtension, File.expand_path("../active_record_cache/relation_extension.rb", __FILE__)

  included do
    # Expire the cache entry both after updates and destroys to ensure it is consistent within a transaction.
    after_destroy :expire_cache_entry
    after_update :expire_cache_entry
    
    # Expire the cache again after a transaction to ensure it is consistent after database changes are committed.
    after_commit :expire_cache_entry
    after_rollback :expire_cache_entry
  end
  
  class << self
    # Get the default cache used by models. Defaults to Rails.cache.
    def cache
      unless defined?(@cache)
        @cache = Rails.cache if defined?(Rails.cache)
      end
      @cache
    end
  
    # Set the default cache used by models.
    def cache=(value)
      @cache = value
    end
    
    # Set the default for classes if they should use the cache or not for the duration of a block.
    # The options hash should be a hash of {class_name => (true|false)}.
    def enable_by_default_on(options)
      current_defaults = Thread.current[:active_record_cache_defaults]
      begin
        defaults = current_defaults ? current_defaults.dup : {}
        Thread.current[:active_record_cache_defaults] = defaults
        options.each do |klass, default|
          defaults[klass.is_a?(Class) ? klass.name : klass.to_s] = !!default
        end
        yield
      ensure
        Thread.current[:active_record_cache_defaults] = current_defaults
      end
    end
  end
  
  # Expire the record out of the cache.
  def expire_cache_entry
    self.class.expire_cache_entry(id)
  end
  
  module ClassMethods
    # Call this method to add a cache to a model. The options allowed are:
    # * :cache - the ActiveSupport::Cache::Store instance to use. By default it will use Rails.cache.
    # * :expires_in - the number of seconds until cache entries will be automatically refreshed (defaults to 1 hour)
    def use_record_cache(options = {})
      class_attribute :record_cache, :instance_reader => false, :instance_writer => false
      self.record_cache = RecordCache.new(self, options)
      scope :from_database, scoped.from_database
      scope :from_cache, scoped.from_cache
    end
    
    def expire_cache_entry(id)
      self.record_cache.expire(id)
    end
  end
end

ActiveRecord::Relation.send(:include, ActiveRecordCache::RelationExtension) unless ActiveRecord::Relation.include?(ActiveRecordCache::RelationExtension)
