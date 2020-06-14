module Elasticsearch
  module Queries
    class PopularAggregation < Base
      def initialize(name:, field:, term_field:, term_value:)
        @name = name
        @field = field
        @term_field = term_field
        @term_value = term_value
      end

      def query
        {
          query: self.class.term_query(field: term_field, values: term_value),
          aggs: {
            name => { terms: { field: field } }
          },
          size: 0
        }
      end

      private

        attr_reader :name, :field, :term_field, :term_value
    end
  end
end
