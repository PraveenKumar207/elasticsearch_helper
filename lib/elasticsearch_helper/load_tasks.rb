require "rake"

module ElasticsearchHelper
  class LoadTasks
    include Rake::DSL if defined? Rake::DSL
    def install_tasks
      load "elasticsearch_helper/tasks/elasticsearch.rake"
    end
  end
end
ElasticsearchHelper::LoadTasks.new.install_tasks
