Dir[File.join(File.expand_path(__dir__), "elasticsearch", "queries", "*.rb")].each { |file| require file }

require "elasticsearch/tasks/indexing"
require "elasticsearch/errors"
require "elasticsearch/searchable"
require "elasticsearch/response_ext"
require "elasticsearch_helper/version"
require "elasticsearch_helper/railtie" if defined?(::Rails::Railtie)
