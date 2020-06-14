module RescueWrapper
  def rescue_elasticsearch_errors_for_test(*class_method_names)
    class_method_names.each do |m|
      proxy = Module.new do
        define_method(m) do |*args|
          begin
            super(*args)
          rescue Faraday::ClientError, Elasticsearch::Transport::Transport::Errors::NotFound => e
            if !Rails.env.test?
              raise e
            end
          end
        end
      end
      singleton_class.prepend proxy
    end
  end
end

module Elasticsearch
  module SearchModelable
    extend ActiveSupport::Concern

    DEFAULT_TOP_TERMS_LIMIT = 20
    DEFAULT_MIN_WORD_LENGTH = 0
    DEFAULT_PAGE = 1
    DEFAULT_PAGE_SIZE = 20

    included do
      extend RescueWrapper

      rescue_elasticsearch_errors_for_test :update_search_document, :delete_search_document
    end

    class_methods do
      def _id(id, type = nil)
        if type.nil?
          id
        else
          "#{type}_#{id}"
        end
      end

      def top_terms(field:, id: nil, text: nil,
                    limit: DEFAULT_TOP_TERMS_LIMIT, min_word_length: DEFAULT_MIN_WORD_LENGTH)
        return [] if id.nil? && text.blank?

        termvector_options = { body: { filter: { max_num_terms: limit, min_word_length: min_word_length } } }
        if id.present?
          termvector_options[:id] = id
        else
          termvector_options[:body].merge!(doc: { field => text })
        end
        termvector_options.merge!(
          field: field,
          index: index_name,
          type: document_type,
          term_statistics: true
        )

        sorted_terms(__elasticsearch__.client.termvector(termvector_options), field)
      end

      def refresh_index
        __elasticsearch__.client.indices.refresh(index: index_name)
      end

      def update_search_document(record_id, type = nil)
        raise Errors::RequiredTypeArgument if multi_model? && type.nil?

        record = if multi_model?
                   model(type).find(record_id)
                 else
                   single_model_name.constantize.find(record_id)
                 end
        Elasticsearch::Model.client.update(update_request(record))
      end

      def delete_search_document(record_id, type = nil)
        raise Errors::RequiredTypeArgument if multi_model? && type.nil?

        Elasticsearch::Model.client.delete(
          index: index_name,
          type: document_type,
          id: _id(record_id, type)
        )
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        # NotPresent OR deleted already
      end

      def update_search_document_later(record_id, type = nil)
        # return if ::Rails.env.development? || ::Rails.env.test?

        delay(priority: 4, queue: "Elasticsearch").update_search_document(record_id)
      end

      def delete_search_document_later(record_id, type = nil)
        # return if ::Rails.env.development? || ::Rails.env.test?

        delay(priority: 4, queue: "Elasticsearch").delete_search_document(record_id)
      end

      private

        def sorted_terms(response, field)
          response = Hashie::Mash.new(response)
          if response.found
            response.term_vectors[field].terms.to_a.sort_by { |x| x.second.score }.reverse
          else
            []
          end
        end

        def update_request(record)
          searchable_model = new(record)
          {
            index: index_name,
            id: searchable_model._id,
            body: {
              doc: searchable_model.as_indexed_json,
              doc_as_upsert: true
            },
            type: document_type
          }
        end
    end
  end
end
