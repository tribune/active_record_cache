module ActiveRecordCache
  class RecordCache  
    attr_reader :cache, :expires_in
      
    def initialize(klass, options = {})
      @klass = klass
      @cache = options[:cache] || ActiveRecordCache.cache
      @expires_in = options[:expires_in] || @cache.options[:expires_in]
      @preload = options[:preload]
      @default = (options[:default].nil? ? false : !!options[:default])
    end
    
    def read(ids)
      ids = ids.first if ids.is_a?(Array) && ids.size == 1
      if ids.is_a?(Array)
        keys = []
        id_key_map = {}
        ids.each do |id|
          key = cache_key(id)
          keys << key
          id_key_map[id] = key
        end
        record_map = @cache.read_multi(*keys)
        missing_ids = ids.reject{|id| record_map[id_key_map[id]]}
        unless missing_ids.empty?
          finder.where(@klass.primary_key => missing_ids).each do |record|
            key = id_key_map[record.id]
            record_map[key] = record
            @cache.write(key, record, :expires_in => @expires_in)
          end
        end
        
        records = []
        ids.each do |id|
          record = record_map[id_key_map[id]]
          records << record if record
        end
        records
      else
        [self[ids]]
      end
    end
    
    # Get a value from the cache by primary key.
    def [](id)
      @cache.fetch(cache_key(id), :expires_in => @expires_in) do
        finder.where(@klass.primary_key => id).first
      end
    end
    
    # Remove an entry from the cache.
    def expire(id)
      @cache.delete(cache_key(id))
    end
    
    # Generate a cache key for a record.
    def cache_key(id)
      "#{@klass.model_name.cache_key}/#{id}"
    end
    
    # Get the default value for whether the cache is enabled or not.
    def default
      defaults = Thread.current[:active_record_cache_defaults]
      if defaults && defaults.include?(@klass.name)
        defaults[@klass.name]
      else
        @default
      end
    end
    
    private
    
    # Return a Relation for finding records to put in the cache.
    def finder
      relation = @klass.from_database.readonly
      relation = relation.preload(@preload) if @preload
      relation
    end
  end
end
