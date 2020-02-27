module ElasticsearchHelper
  module Queries
    class SignificantAggregation < Base
      SUPPORTED_TYPES = %i(significant_terms significant_text).freeze

      def initialize(type:, field:, term_field:, term_value:)
        @type = type
        @field = field
        @term_field = term_field
        @term_value = term_value
      end

      def query
        {
          query: self.class.term_query(field: term_field, values: term_value),
          aggregations: {
            type => { type => { field: field } }
          }
        }
      end

      private

        attr_reader :field, :term_field, :term_value

        def type
          raise 'Not a supported type' if !@type.in?(SUPPORTED_TYPES)

          @type
        end
    end
  end
end
