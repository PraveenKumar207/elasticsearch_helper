require "elasticsearch/queries/base"

module Elasticsearch
  module Queries
    class BoolSearch < Base
      def initialize(should: [], must: [], must_not: [], filter: [], filters: {}, **options)
        @should = Array.wrap(should)
        @must = Array.wrap(must)
        @must_not = Array.wrap(must_not)
        @filter = Array.wrap(filter)
        @filters = filters
        @options = options
      end

      def query
        { query: bool_query }
      end

      def bool_query
        base_bool_query.tap do |q|
          add_filters!
          q[:bool][:minimum_should_match] = minimum_should_match if minimum_should_match.present?
          q[:bool][:boost] = boost if boost.present?
        end
      end

      private

        attr_reader :should, :must_not, :must, :filter, :filters, :options

        def base_bool_query
          @_base_bool_query ||= {
            bool: {
              must: must,
              must_not: must_not,
              should: should,
              filter: filter
            }
          }
        end

        def minimum_should_match
          options[:minimum_should_match]
        end

        def boost
          options[:boost]
        end

        def add_filters!
          valid_filters.map do |field, value|
            base_bool_query[:bool][:filter] << if value.is_a?(Range)
                                                 self.class.range_query(field: field, value: value)
                                               else
                                                 self.class.term_query(field: field, values: value)
                                               end
          end
        end

        def valid_filters
          filters.reject(&method(:invalid_value?))
        end

        def invalid_value?(_, value)
          value.nil? || ((value.is_a?(Array) || value.is_a?(Hash)) && value.empty?)
        end
    end
  end
end
