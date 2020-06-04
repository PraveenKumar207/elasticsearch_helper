module ElasticsearchHelper
  module Queries
    # PhraseSuggesterSearch requires trigram and reverse to be defined for the field
    class PhraseSuggesterSearch < Base
      DEFAULT_SIZE = 1
      DEFAULT_SUGGEST_MODE = "missing".freeze
      REVERSE_ANALYZER = "reverse_analyzer".freeze

      def initialize(suggestion_name:, phrase:, field:, **options)
        @suggestion_name = suggestion_name
        @phrase = phrase
        @field = field
        @options = options
      end

      def query
        suggest_query.tap do |q|
          if collate.present?
            q[:suggest][suggestion_name][:phrase][:collate] = collate
          end
        end
      end

      private

        attr_reader :suggestion_name, :phrase, :field, :options

        def collate_query
          options[:collate_query]
        end

        def prune
          options[:prune]
        end

        def collate
          return if collate_query.nil?

          { query: { source: {} } }.tap do |h|
            h[:query][:source] = collate_query

            if prune.present?
              h[:prune] = prune
            end
          end
        end

        def trigram_field
          "#{field}.trigram"
        end

        def reverse_field
          "#{field}.reverse"
        end

        def suggest_query
          {
            suggest: {
              text: phrase,
              suggestion_name => {
                phrase: {
                  field: trigram_field,
                  size: DEFAULT_SIZE,
                  direct_generator: [
                    {
                      field: trigram_field,
                      suggest_mode: DEFAULT_SUGGEST_MODE
                    },
                    {
                      field: reverse_field,
                      suggest_mode: DEFAULT_SUGGEST_MODE,
                      pre_filter: REVERSE_ANALYZER,
                      post_filter: REVERSE_ANALYZER
                    }
                  ]
                }
              }
            }
          }
        end
    end
  end
end
