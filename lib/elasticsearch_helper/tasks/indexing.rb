require 'ruby-progressbar'

module ElasticsearchHelper
  module Tasks
    class Indexing
      SINGLE_MODEL_IMPORT_RELATION = 'ES_IMPORT_RELATION'.freeze
      MULTI_MODEL_IMPORT_RELATION = 'ES_IMPORT_RELATIONS'.freeze
      DEFAULT_BATCH_SIZE = 1000

      def self.delete(index_name, force = false)
        if index_exists?(index_name)
          if force || !aliases.include?(index_name)
            Elasticsearch::Model.client.indices.delete index: index_name
            puts "Deleted Index #{index_name}"
          else
            puts 'Remove aliases before deleting index'
          end
        else
          puts "Index #{index_name} does not exists"
        end
      end

      def self.aliases
        Elasticsearch::Model.client.indices.get_alias.reject { |_, value| value['aliases'].empty? }.keys
      end

      def self.index_exists?(index_name)
        Elasticsearch::Model.client.indices.exists(index: index_name)
      end

      def self.show
        puts Elasticsearch::Model.client.cat.indices
      end

      def self.copy(model:, source_index:, source_host: nil)
        new(model).copy(source_index, source_host)
      end

      def initialize(model, options = {})
        @model = model
        @options = options
      end

      def create
        create_index

        if import?
          if model.multimodel
            model::MODELS.each(&method(:import))
          else
            import
          end

          if switch?
            switch_alias(new_index_name)
          end
        end
      end

      def copy(source_index, source_host)
        create_index

        Elasticsearch::Model.client.reindex(
          body: copy_index_query(source_index, source_host),
          wait_for_completion: false
        )
      end

      def switch_alias(new_index)
        actions = []
        actions << { add: { index: new_index, alias: index_name } }
        aliases.each do |old_index|
          actions << { remove: { index: old_index, alias: index_name } }
        end

        Elasticsearch::Model.client.indices.update_aliases(body: { actions: actions })
        puts "Alias switched for #{index_name} with #{new_index}"
      end

      def aliases
        @_aliases ||= begin
                        Elasticsearch::Model.client.indices.get_alias(index: index_name).keys
                      rescue Elasticsearch::Transport::Transport::Errors::NotFound
                        []
                      end
      end

      def show
        puts Elasticsearch::Model.client.cat.indices index: "*#{index_name}"
      end

      def cleanup
        indexes_to_cleanup.each { |full_index_name| self.class.delete(full_index_name) }
      end

      private

        attr_reader :model, :options

        delegate :mappings, :settings, to: :index
        delegate :create_index!, :refresh_index!, to: :elasticsearch
        delegate :index_name, :document_type, to: :model

        def create_index
          create_index!(
            index: new_index_name,
            settings: settings,
            mappings: mappings
          )
          puts "Created Index #{new_index_name}"
        end

        def copy_index_query(source_index, source_host)
          if source_host.present?
            {
              source: {
                remote: { host: source_host },
                index: source_index
              },
              dest: { index: new_index_name }
            }
          else
            {
              source: { index: source_index },
              dest: { index: new_index_name }
            }
          end
        end

        def index
          @_index ||= Elasticsearch::Indexes::Base.index(model)
        end

        def elasticsearch
          @_elasticsearch ||= model.__elasticsearch__
        end

        def import?
          options.fetch(:import, false)
        end

        def switch?
          options.fetch(:switch, false)
        end

        def import(import_model = model)
          progress_bar = create_progress_bar(import_model)
          batch_size = if model.const_defined?('INDEX_BATCH_SIZE')
                         model.const_get('INDEX_BATCH_SIZE')
                       else
                         DEFAULT_BATCH_SIZE
                       end

          relation(import_model).find_in_batches(batch_size: batch_size) do |batch|
            Elasticsearch::Model.client.bulk(
              index: new_index_name,
              type: document_type,
              body: body_from(batch)
            )
            begin
              progress_bar.progress += batch.count
            rescue ProgressBar::InvalidProgressError
            end
          end
        end

        def create_progress_bar(import_model)
          ProgressBar.create(
            title: "Completed Importing #{import_model.name}",
            total: import_count(import_model),
            format: "%a %b\u{15E7}%i %p%% %t %e",
            progress_mark: ' ',
            remainder_mark: "\u{FF65}"
          )
        end

        def relation(import_model)
          if relation_from_multimodel?(import_model)
            model.const_get(MULTI_MODEL_IMPORT_RELATION).fetch(import_model).call
          elsif !model.multimodel && model.const_defined?(SINGLE_MODEL_IMPORT_RELATION)
            model.const_get(SINGLE_MODEL_IMPORT_RELATION).call
          else
            model
          end
        end

        def relation_from_multimodel?(import_model)
          model.multimodel &&
            model.const_defined?(MULTI_MODEL_IMPORT_RELATION) &&
            model.const_get(MULTI_MODEL_IMPORT_RELATION).key?(import_model)
        end

        def import_count(import_model)
          relation(import_model).count
        end

        def body_from(batch)
          if model.multimodel
            model.as_indexed_json(batch).map { |data| { index: { data: data } } }
          else
            batch.map { |obj| { index: { _id: obj.id, data: obj.as_indexed_json } } }
          end
        end

        def new_index_name
          @_new_index_name ||= Time.zone.now.strftime('%Y%m%d_%H%M%S_') + index_name
        end

        # All indexes except current aliases and the latest
        # index other than current aliases can be deleted
        def indexes_to_cleanup
          Elasticsearch::Model.client.indices.get_aliases.keys.select do |full_index_name|
            (index_name.in? full_index_name) && (aliases.exclude? full_index_name)
          end.sort.slice(0...-1)
        end
    end
  end
end
