module Elasticsearch
  module Errors
    class ModelTypeRedefintionError < StandardError
      def message
        "Cannot redefine search model type"
      end
    end

    class ESImportRelationWithoutSingleModel < StandardError
      def message
        "Cannot define es_import_relation without defining single_model"
      end
    end

    class ESImportModelRelationWithoutMultiModel < StandardError
      def message
        "Cannot define es_import_model_relation without defining multi_model"
      end
    end

    class UndefinedQueryError < StandardError
      def message
        "Need to define query method"
      end
    end

    class RequiredTypeArgument < StandardError
      def message
        "Required argument type for mult_model document updation and deletion"
      end
    end
  end
end
