module ElasticsearchHelper
  module Queries
    class MultiMatchSearch < Base
      DEFAULT_OPERATOR = "and".freeze

      def initialize(query_string:, fields_with_boosts:, **options)
        @query_string = query_string
        @fields_with_boosts = fields_with_boosts
        @options = options
      end

      def query
        multi_match_query.tap do |q|
          if analyzer.present?
            q[:multi_match][:analyzer] = analyzer
          end
        end
      end

      private

        attr_reader :fields_with_boosts, :query_string, :options

        def operator
          options.fetch(:operator, DEFAULT_OPERATOR)
        end

        def analyzer
          options[:analyzer]
        end

        def multi_match_query
          {
            multi_match: {
              query: query_string,
              fields: fields,
              operator: operator
            }
          }
        end

        def fields
          fields_with_boosts.map do |field, boost|
            self.class.field_boost_query(field: field, boost: boost)
          end
        end
    end
  end
end
