module Elasticsearch
  module MultiModelable
    extend ActiveSupport::Concern

    class_methods do
      def available_types
        multi_model_names.map(&:constantize).map(&method(:type))
      end

      def type(obj)
        klass = model(obj)
        return if klass.nil?

        I18n.t("models.#{klass}.readable", default: klass.model_name.element)
      end

      def model(obj)
        if obj.is_a? String
          model_from_type(obj)
        else
          klass = if obj.is_a?(Class)
                    obj
                  else
                    obj.class
                  end
          if klass.name.in? multi_model_names
            klass
          else
            multi_model_names.map(&:constantize).find { |model| klass.base_class == model }
          end
        end
      end

      private

        def model_from_type(type)
          multi_model_names.map(&:constantize).find { |model| type(model) == type }
        end
    end
  end
end
