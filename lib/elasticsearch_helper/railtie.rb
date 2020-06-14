require "rails"

module ElasticsearchHelper
  class Railtie < Rails::Railtie
    railtie_name :elasticsearch_helper

    rake_tasks do
      Dir[File.join(File.expand_path(__dir__), "..", "elasticsearch", "tasks", "*.rake")].each { |ext| load ext }
    end
  end
end
