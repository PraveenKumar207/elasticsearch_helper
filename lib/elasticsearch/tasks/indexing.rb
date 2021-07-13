require "active_support/core_ext/module"
require "ruby-progressbar"

module Elasticsearch
  module Tasks
    class Indexing
      def self.delete(index_name, force = false)
        if index_exists?(index_name)
          if force || aliases.exclude?(index_name)
            Elasticsearch::Model.client.indices.delete index: index_name
            puts "Deleted Index #{index_name}"
          else
            puts "Remove aliases before deleting index"
          end
        else
          puts "Index #{index_name} does not exists"
        end
      end

      def self.aliases
        Elasticsearch::Model.client.indices.get_alias.reject { |_, value| value["aliases"].empty? }.keys
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
          if model.multi_model?
            model.multi_model_names.each(&method(:import))
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

        delegate :create_index!, :refresh_index!, to: :elasticsearch
        delegate :index_name, :mappings, :settings, to: :model
        # delegate :index_name, :document_type, :mappings, :settings, to: :model

        def create_index
          create_index!(
            index: new_index_name,
            settings: settings.to_hash,
            mappings: mappings.to_hash
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
          batch_size = model.record_import_batch_size

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
            title: "Completed Importing #{import_model}",
            total: import_count(import_model),
            format: "%a %b\u{15E7}%i %p%% %t %e",
            progress_mark: " ",
            remainder_mark: "\u{FF65}"
          )
        end

        def relation(import_model)
          if model.multi_model?
            model.multi_model_import_relation(import_model)
          else
            model.single_model_import_relation
          end
        end

        def import_count(import_model)
          relation(import_model).count
        end

        def body_from(batch)
          batch.map do |obj|
            searchable_object = model.new(obj)
            { index: { _id: searchable_object._id, data: searchable_object.as_indexed_json } }
          end
        end

        def new_index_name
          @_new_index_name ||= Time.zone.now.strftime("%Y%m%d_%H%M%S_") + index_name
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
