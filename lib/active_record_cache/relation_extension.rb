module ActiveRecordCache
  module RelationExtension
    extend ActiveSupport::Concern
    
    SIMPLE_ORDER_BY = /^([a-z][a-z0-9_]*)( ?((asc|desc)(ending)?)?)$/i
    
    included do
      alias_method_chain :to_a, :record_cache
      alias_method_chain :merge, :record_cache
      attr_accessor :query_from_cache_value
    end
    
    # Calling +from_database+ on a Relation will force the query to bypass the cache.
    def from_database
      relation = clone
      relation.query_from_cache_value = false
      relation
    end
    
    # Calling +from_database+ on a Relation will force the query to bypass the cache.
    def from_cache
      relation = clone
      relation.query_from_cache_value = true
      relation
    end
    
    # Override the to_a method to look in the cache.
    def to_a_with_record_cache #:nodoc:
      if !loaded? && cacheable_query?
        ids = get_where_ids
        unless ids.blank?
          records = klass.record_cache.read(ids)
          records = records[0, limit_value.to_i] if limit_value
          records = records.sort_by_field(order_values.first) unless order_values.empty?
          if logger && logger.debug?
            logger.debug("  #{klass.name} LOAD FROM RECORD CACHE #{to_sql}")
          end
          @records = records
          @loaded = true
        end
      end
      to_a_without_record_cache
    end
    
    # Override the merge function so that the query_from_cache_value gets merged.
    def merge_with_record_cache(relation) #:nodoc:
      merged_relation = merge_without_record_cache(relation)
      merged_relation.query_from_cache_value = relation.query_from_cache_value
      merged_relation
    end
    
    private
    
    # Return true if the query is cacheable. Queries are only cacheable if there is at most one where clause and that
    # clause searches only by one or more id's. The query must also not do any joins, offsets, or groupings. Any order
    # clause must be a simple order by one of the columns.
    def cacheable_query?
      return false unless klass.respond_to?(:record_cache)
      from_cache = (query_from_cache_value.nil? ? klass.record_cache.default : query_from_cache_value)
      return false unless from_cache
      return false unless where_values.size == (klass.finder_needs_type_condition? ? 2 : 1)
      return false unless order_values.blank? || (order_values.size == 1 && order_values.first.to_s.match(SIMPLE_ORDER_BY))
      select_col = select_values.first
      select_col = select_col.name if select_col && select_col.respond_to?(:name)
      select_star = select_values.blank? || (select_values.size == 1 && select_col == "*")
      return false unless select_star
      return false unless group_values.blank? && includes_values.blank? && eager_load_values.blank? && preload_values.blank? && joins_values.blank? && having_values.blank? && offset_value.blank?
      return false unless from_value.blank? && lock_value.blank?
      true
    end
    
    # Get the primary key values used in the query. This will only return a value if the query
    # had exactly one where clause by primary key.
    def get_where_ids
      where_hash = where_values_hash.with_indifferent_access
      if where_hash.size == (klass.finder_needs_type_condition? ? 2 : 1)
        bind_index = 0
        Array(where_hash[klass.primary_key]).collect do |id|
          if id == "?"
            bind_val = bind_values[bind_index]
            id = bind_val.last if bind_val
            bind_index += 1
          end
          begin
            Integer(id)
          rescue ArgumentError
            return nil
          end
        end
      elsif where_hash.empty? && (!defined?(bind_values) || bind_values.empty?)
        sql = where_values.first
        if sql.is_a?(String)
          pk_column = "#{klass.connection.quote_table_name(klass.table_name)}.#{klass.connection.quote_column_name(klass.primary_key)}"
          pattern = Regexp.new("^\\s*\\(?\\s*#{Regexp.escape(pk_column)}(\\s*(=\\s*(\\d+))|(\\s+IN\\s+\\(([\\d\\s,]+)\\)))\\s*\\)?\\s*$", true)
          if sql.match(pattern)
            single_id = $~[3].to_i if $~[3]
            multiple_ids = $~[5].split(',').collect{|n| n.to_i} if $~[5]
            single_id || multiple_ids
          end
        end
      end
    end
  end
end
