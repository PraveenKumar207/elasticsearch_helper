namespace :elasticsearch do
  namespace :index do
    desc "Create index by optionally importing data and switch alias after import"
    task create: :environment do
      raise "CLASS should be given" unless ENV["CLASS"]

      model = ENV["CLASS"].constantize
      import = ENV["IMPORT"].to_i > 0
      switch = ENV["SWITCH"].to_i > 0
      Elasticsearch::Tasks::Indexing.new(model, import: import, switch: switch).create
    end

    desc "Delete index with the provided name"
    task delete: :environment do
      raise "INDEX should be given" unless ENV["INDEX"]

      index_name = ENV["INDEX"]
      force = ENV["FORCE"].to_i > 0
      Elasticsearch::Tasks::Indexing.delete(index_name, force)
    end

    desc "Cleanup old indexes keeping current alias and one backup indices"
    task cleanup: :environment do
      raise "CLASS should be given" unless ENV["CLASS"]

      model = ENV["CLASS"].constantize
      Elasticsearch::Tasks::Indexing.new(model).cleanup
    end

    desc "Switch alias for the class to provided index name"
    task switch_alias: :environment do
      raise "INDEX and CLASS should be given" unless ENV["INDEX"] && ENV["CLASS"]

      index_name = ENV["INDEX"]
      model = ENV["CLASS"].constantize
      Elasticsearch::Tasks::Indexing.new(model).switch_alias(index_name)
    end

    desc "Show aliases"
    task show_aliases: :environment do
      if ENV["CLASS"].present?
        model = ENV["CLASS"].constantize
        puts Elasticsearch::Tasks::Indexing.new(model).aliases
      else
        puts Elasticsearch::Tasks::Indexing.aliases
      end
    end

    desc "Show index details"
    task show: :environment do
      if ENV["CLASS"].present?
        model = ENV["CLASS"].constantize
        Elasticsearch::Tasks::Indexing.new(model).show
      else
        Elasticsearch::Tasks::Indexing.show
      end
    end

    desc "Copy index from another environment"
    task copy: :environment do
      raise "SOURCE_INDEX, CLASS should be given" unless ENV["SOURCE_INDEX"] && ENV["CLASS"]

      model = ENV["CLASS"].constantize
      Elasticsearch::Tasks::Indexing.copy(
        source_host: ENV["SOURCE_HOST"],
        source_index: ENV["SOURCE_INDEX"],
        model: model
      )
    end
  end
end
