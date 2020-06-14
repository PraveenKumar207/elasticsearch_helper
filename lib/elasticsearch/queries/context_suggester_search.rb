module Elasticsearch
  module Queries
    class ContextSuggesterSearch < Base
      DEFAULT_SIZE = 20
      DEFAULT_FUZZY = false

      def initialize(suggestion_name:, prefix:, field:, contexts: [], **options)
        @suggestion_name = suggestion_name
        @prefix = prefix
        @field = field
        @contexts = contexts
        @options = options
      end

      def query
        {
          suggest: {
            suggestion_name => {
              prefix: prefix,
              completion: {
                field: field,
                size: size,
                contexts: contexts,
                fuzzy: fuzzy,
                skip_duplicates: skip_duplicates
              }
            }
          }
        }
      end

      private

        attr_reader :suggestion_name, :prefix, :field, :contexts, :options

        def size
          options[:size] || DEFAULT_SIZE
        end

        def fuzzy
          options[:fuzzy] || DEFAULT_FUZZY
        end

        def skip_duplicates
          options[:skip_duplicates] || false
        end
    end
  end
end
