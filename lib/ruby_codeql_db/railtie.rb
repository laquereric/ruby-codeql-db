# frozen_string_literal: true

module RubyCodeqlDb
  # Rails integration for automatic rake task loading
  class Railtie < ::Rails::Railtie
    railtie_name :ruby_codeql_db

    rake_tasks do
      load File.expand_path("../tasks/ruby_codeql_db.rake", __dir__)
    end

    initializer "ruby_codeql_db.configure" do |app|
      # Set default configuration for Rails applications
      RubyCodeqlDb.configure do |config|
        config.source_root = Rails.root.to_s if defined?(Rails.root)
        config.default_database_path = Rails.root.join("tmp", "ruby_codeql_db").to_s if defined?(Rails.root)
        
        # Exclude Rails-specific directories
        config.exclude_patterns += %w[
          public/assets
          public/packs
          storage
          tmp/cache
          db/migrate
        ]
      end
    end
  end
end

