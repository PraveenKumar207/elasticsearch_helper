module Elasticsearch
  module Queries
    class MatchPhraseSearch < Base
      def initialize(query_string:, field:)
        @query_string = query_string
        @field = field
      end

      def query
        {
          match_phrase: {
            field => query_string
          }
        }
      end

      private

        attr_reader :field, :query_string
    end
  end
end
