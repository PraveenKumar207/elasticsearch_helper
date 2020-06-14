require "elasticsearch/search_modelable"
require "elasticsearch/configuration_methods"
require "elasticsearch/model"

module Elasticsearch
  module Searchable
    extend ActiveSupport::Concern
    include Elasticsearch::SearchModelable
    include Elasticsearch::ConfigurationMethods

    included do
      include Elasticsearch::Model
      extend ActiveModel::Naming

      index_name "#{model_name.plural}-#{::Rails.env}"
      document_type model_name.element
      attr_reader :object
    end

    def initialize(object)
      @object = object
    end

    def as_indexed_json(select: [])
      from_attributes(select: select).merge(from_methods(select: select))
    end

    def _id
      if self.class.multi_model?
        self.class._id(unique_id, self.class.type(object))
      else
        self.class._id(unique_id)
      end
    end

    private

      def from_attributes(select: [])
        Hash.new.tap do |attributes_json|
          self.class.index_json_attributes.each do |attribute|
            next if select.present? && select.exclude?(attribute)

            attributes_json[attribute] = object.try(attribute)
          end
        end
      end

      def from_methods(select: [])
        Hash.new.tap do |methods_json|
          self.class.index_json_methods.each do |method_name|
            next if select.present? && select.exclude?(method_name)

            methods_json[method_name] = send(method_name)
          end
        end
      end

      def unique_id
        if respond_to?(:id, true)
          id
        else
          object.send(object.class.primary_key)
        end
      end
  end
end
