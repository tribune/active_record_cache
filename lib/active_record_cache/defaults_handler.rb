module ActiveRecordCache
  # Rack handler that sets the default for classes if they will use the cache for queries.
  class DefaultsHandler
    def initialize(app, options)
      @app = app
      @options = options
    end
    
    def call(env)
      ActiveRecordCache.enable_by_default_on(@options) do
        @app.call(env)
      end
    end
  end
end
