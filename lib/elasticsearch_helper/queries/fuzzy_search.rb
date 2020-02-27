module ElasticsearchHelper
  module Queries
    class FuzzySearch < Base
      MAX_EDIT_DISTANCE = 1
      OPERATOR = 'and'.freeze

      def initialize(query_string:, field:, filters: {}, **options)
        @query_string = query_string
        @field = field
        @filters = filters
        @options = options
      end

      def query
        BoolSearch.new(must: match_query, filters: filters).query
      end

      private

        attr_reader :query_string, :field, :filters, :options

        def operator
          options[:operator] || OPERATOR
        end

        def match_query
          [
            match: {
              field => {
                query: query_string,
                fuzziness: MAX_EDIT_DISTANCE,
                operator: operator
              }
            }
          ]
        end
    end
  end
end
