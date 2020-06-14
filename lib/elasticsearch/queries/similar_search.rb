require "active_support/core_ext/hash/indifferent_access"
require "elasticsearch/queries/bool_search"

module Elasticsearch
  module Queries
    class SimilarSearch < Base
      DEFAULT_MINIMUM_SHOULD_MATCH = "50%".freeze
      DEFAULT_MAX_QUERY_TERMS = 20
      DEFAULT_BOOST_TERMS = 1
      DEFAULT_MIN_TERM_FREQ = 1
      DEFAULT_MIN_DOC_FREQ = 5
      DEFAULT_MIN_WORD_LENGTH = 0

      def initialize(fields:, ids: [], docs: [], filter: [], filters: {}, **options)
        @ids = ids
        @docs = docs
        @fields = fields
        @options = options.with_indifferent_access
        @filters = filters
        @filter = filter
      end

      def query
        BoolSearch.new(must: more_like_this_query, filter: filter, filters: filters).query
      end

      def more_like_this_query
        {
          more_like_this: {
            fields: fields,
            like: like,
            minimum_should_match: minimum_should_match,
            boost_terms: boost_terms,
            max_query_terms: max_query_terms,
            min_doc_freq: min_doc_freq,
            min_word_length: min_word_length,
            min_term_freq: DEFAULT_MIN_TERM_FREQ
          }
        }.tap do |q|
          q[:more_like_this][:boost] = boost if boost.present?
        end
      end

      private

        attr_reader :ids, :docs, :fields, :filters, :filter, :options

        def minimum_should_match
          options[:minimum_should_match] || DEFAULT_MINIMUM_SHOULD_MATCH
        end

        def max_query_terms
          options[:max_query_terms] || DEFAULT_MAX_QUERY_TERMS
        end

        def min_doc_freq
          options[:min_doc_freq] || DEFAULT_MIN_DOC_FREQ
        end

        def boost
          options[:boost]
        end

        def boost_terms
          options[:boost_terms] || DEFAULT_BOOST_TERMS
        end

        def min_word_length
          options[:min_word_length] || DEFAULT_MIN_WORD_LENGTH
        end

        def like
          Array.new.tap do |like|
            ids.each { |id| like.append(_id: id) }
            docs.each { |doc| like.append(doc: doc) }
          end
        end
    end
  end
end
