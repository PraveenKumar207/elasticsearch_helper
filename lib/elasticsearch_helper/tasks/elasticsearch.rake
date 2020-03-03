require "rake"
namespace :elasticsearch do

  desc 'Elastic search related tasks for indexing, setup , copy'
  namespace :index do
    task create: :environment do
      raise 'CLASS should be given' unless ENV['CLASS']

      model = ENV['CLASS'].constantize
      import = ENV['IMPORT'].to_i > 0
      switch = ENV['SWITCH'].to_i > 0
      ElasticsearchHelper::Tasks::Indexing.new(model, import: import, switch: switch).create
    end

    task delete: :environment do
      raise 'INDEX should be given' unless ENV['INDEX']

      index_name = ENV['INDEX']
      force = ENV['FORCE'].to_i > 0
      ElasticsearchHelper::Tasks::Indexing.delete(index_name, force)
    end

    desc 'Cleanup old indexes keeping current alias and one backup indices'
    task cleanup: :environment do
      raise 'CLASS should be given' unless ENV['CLASS']

      model = ENV['CLASS'].constantize
      ElasticsearchHelper::Tasks::Indexing.new(model).cleanup
    end

    task switch_alias: :environment do
      raise 'INDEX and CLASS should be given' unless ENV['INDEX'] && ENV['CLASS']

      index_name = ENV['INDEX']
      model = ENV['CLASS'].constantize
      ElasticsearchHelper::Tasks::Indexing.new(model).switch_alias(index_name)
    end

    task show_aliases: :environment do
      if ENV['CLASS'].present?
        model = ENV['CLASS'].constantize
        puts ElasticsearchHelper::Tasks::Indexing.new(model).aliases
      else
        puts ElasticsearchHelper::Tasks::Indexing.aliases
      end
    end

    task show: :environment do
      if ENV['CLASS'].present?
        model = ENV['CLASS'].constantize
        ElasticsearchHelper::Tasks::Indexing.new(model).show
      else
        ElasticsearchHelper::Tasks::Indexing.show
      end
    end

    task copy: :environment do
      raise 'SOURCE_INDEX, CLASS should be given' unless ENV['SOURCE_INDEX'] && ENV['CLASS']

      model = ENV['CLASS'].constantize
      ElasticsearchHelper::Tasks::Indexing.copy(
        source_host: ENV['SOURCE_HOST'],
        source_index: ENV['SOURCE_INDEX'],
        model: model
      )
    end
  end

  task setup: :environment do
    ElasticsearchHelper::Tasks::Setup.new(es_version: ENV['ELASTICSEARCH_VERSION'],
                                    cerebro_version: ENV['CEREBRO_VERSION'],
                                    es_setup_dir: ENV['ELASTICSEARCH_SETUP_DIR']).run
  end
end
