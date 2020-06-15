require "elasticsearch/multi_modelable"

module Elasticsearch
  module ConfigurationMethods
    extend ActiveSupport::Concern
    DEFAULT_IMPORT_BATCH_SIZE = 1000

    class_methods do
      def single_model(model_name)
        raise Errors::ModelTypeRedefintionError if defined?(@_single_model_name) || defined?(@_multi_model_names)

        @_single_model_name = model_name
      end

      def es_import_relation(&block)
        raise "Block needed" unless block_given?
        raise Errors::ESImportRelationWithoutSingleModel unless defined?(@_single_model_name)

        @_single_model_import_relation = block
      end

      def multi_model(*args)
        raise Errors::ModelTypeRedefintionError if defined?(@_single_model_name) || defined?(@_multi_model_names)

        include MultiModelable
        @_multi_model_names = args
      end

      def es_import_model_relation(model_name, &block)
        raise "Block needed" unless block_given?
        raise Errors::ESImportModelRelationWithoutMultiModel unless defined?(@_multi_model_names)

        @_multi_model_import_relation_hash = {} unless defined?(@_multi_model_import_relation_hash)
        @_multi_model_import_relation_hash[model_name] = block
      end

      def index_json(attributes: [], methods: [])
        @_index_json_attributes = attributes.dup.freeze
        @_index_json_methods = methods.dup.freeze
      end

      def import_batch_size(size)
        @_import_batch_size = size
      end

      def record_import_batch_size
        (defined?(@_import_batch_size) && @_import_batch_size) || DEFAULT_IMPORT_BATCH_SIZE
      end

      def index_json_attributes
        (defined?(@_index_json_attributes) && @_index_json_attributes) || [].freeze
      end

      def index_json_methods
        (defined?(@_index_json_methods) && @_index_json_methods) || [].freeze
      end

      def multi_model?
        !!defined?(@_multi_model_names)
      end

      def single_model?
        !!defined?(@_single_model_name)
      end

      def multi_model_names
        @_multi_model_names
      end

      def single_model_name
        @_single_model_name
      end

      def single_model_import_relation
        return unless single_model?

        (defined?(@_single_model_import_relation) && @_single_model_import_relation.call) ||
          single_model_name.constantize
      end

      def multi_model_import_relation(model_name)
        return unless  multi_model?
        return unless multi_model_names.include? model_name

        multi_model_import_relation_hash[model_name]&.call || model_name.constantize
      end

      private

        def multi_model_import_relation_hash
          (defined?(@_multi_model_import_relation_hash) && @_multi_model_import_relation_hash.dup) || {}
        end
    end
  end
end
