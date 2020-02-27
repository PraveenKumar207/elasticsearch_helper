module ElasticsearchHelper
  module Errors
    class UndefinedIndexError < StandardError
      def message
        'Need to define index'
      end
    end

    class UndefinedMappingsError < StandardError
      def message
        'Need to define mappings for the index'
      end
    end

    class UndefinedSettingsError < StandardError
      def message
        'Need to define settings for the index'
      end
    end

    class UndefinedQueryError < StandardError
      def message
        'Need to define query method'
      end
    end

    class MissingElasticsearchSetupError < StandardError
      def message
        'Missing elasticsearch setup'
      end
    end
  end
end
