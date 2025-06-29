# frozen_string_literal: true

require_relative "codeql_db/version"
require_relative "codeql_db/configuration"
require_relative "codeql_db/database/manager"
require_relative "codeql_db/cli/wrapper"
require_relative "codeql_db/statistics/analyzer"

module CodeqlDb
  class Error < StandardError; end
  class DatabaseError < Error; end
  class CLIError < Error; end
  class ConfigurationError < Error; end

  # Main entry point for CodeQL database operations
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
      configuration
    end

    def create_database(source_path, database_path = nil, options = {})
      Database::Manager.new(configuration).create(source_path, database_path, options)
    end

    def analyze_database(database_path, options = {})
      Statistics::Analyzer.new(configuration).analyze(database_path, options)
    end

    def list_files(database_path, options = {})
      Database::Manager.new(configuration).list_files(database_path, options)
    end
  end
end

# Load rake tasks if in Rails environment
if defined?(Rails)
  require_relative "codeql_db/railtie"
elsif defined?(Rake)
  # Load rake tasks for non-Rails environments only if Rake is already loaded
  load File.expand_path("tasks/codeql_db.rake", __dir__)
end
