module ElasticsearchHelper
  module Indexes
    class Base
      include Analysis::Analyzers
      include Analysis::Filters
      include Analysis::CharFilters

      ANALYSIS_MEMBERS = %i(analyzers filters char_filters tokenizers).freeze
      DEFAULT_FILTERS = %i(english_filters).freeze
      DEFAULT_ANALYZERS = %i(custom_english_analyzer).freeze
      DEFAULT_TOKENIZERS = %i().freeze
      DEFAULT_CHAR_FILTERS = %i().freeze

      def settings
        raise ElasticsearchHelper::Errors::UndefinedSettingsError
      end

      def mappings
        raise ElasticsearchHelper::Errors::UndefinedMappingsError
      end

      private

        def base_mappings
          {
            document_type => {
              dynamic: "strict",
              properties: {
                id: { type: :long }
              }
            }
          }.with_indifferent_access
        end

        def base_settings
          initial_settings.tap do
            add_analysis_members!
          end
        end

        def initial_settings
          @_initial_settings ||= { index: { number_of_shards: 1 } }.with_indifferent_access
        end

        def add_analysis_members!
          initial_settings[:analysis] = {}

          ANALYSIS_MEMBERS.each do |member|
            member_settings = settings_for(member)
            if member_settings.present?
              initial_settings[:analysis][member.to_s.singularize] = member_settings
            end
          end
        end

        def settings_for(analysis_member)
          Hash.new.tap do |hash|
            elements_for(analysis_member).each do |element|
              hash.merge!(send(element))
            end
          end
        end

        def elements_for(analysis_member)
          Array.new.tap do |elements|
            elements.concat(default_elements_for(analysis_member))
            if analysis_member.upcase.in? self.class.constants
              elements.concat(self.class.const_get(analysis_member.upcase))
            end
          end
        end

        def default_elements_for(analysis_member)
          self.class.const_get("DEFAULT_#{analysis_member}".upcase)
        end

        # Commonly used field options

        def default_field_options
          {
            analyzer: "custom_english_analyzer",
            index_options: "offsets",
            term_vector: "yes",
            type: "text"
          }
        end

        def edge_ngram_options
          {
            edge_ngram: {
              analyzer: "edge_ngram_analyzer",
              index_options: "offsets",
              term_vector: "yes",
              type: "text"
            }
          }
        end

        def keyword_options
          { keyword: { type: :keyword } }
        end

        def shingle_options
          {
            analyzer: "shingle_analyzer",
            index_options: "offsets",
            term_vector: "yes",
            type: "text"
          }
        end
    end
  end
end
