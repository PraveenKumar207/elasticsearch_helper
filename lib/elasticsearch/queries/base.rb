module Elasticsearch
  module Queries
    class Base
      def query
        raise Errors::UndefinedQueryError
      end

      class << self
        def exists_query(field:, nested: nil)
          query = { exists: { field: field } }
          query = nested(query, nested) if nested.present?
          query
        end

        def term_query(field:, values:, boost: nil, nested: nil)
          field = "#{nested}.#{field}" if nested.present?
          query = { terms: { field => Array.wrap(values) } }
          query[:terms][:boost] = boost if boost.present?
          query = nested(query, nested) if nested.present?
          query
        end

        def range_query(field:, value:)
          {
            range: {
              field => {
                gte: value.min,
                lte: value.max
              }
            }
          }
        end

        def field_boost_query(field:, boost:)
          boost = boost.to_i

          if boost.in? [0, 1]
            field
          else
            "#{field}^#{boost}"
          end
        end

        private

          def nested(query, path)
            { nested: { path: path, query: query } }
          end
      end
    end
  end
end
