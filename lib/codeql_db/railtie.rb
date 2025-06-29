# frozen_string_literal: true

module CodeqlDb
  # Rails integration for automatic rake task loading
  class Railtie < Rails::Railtie
    railtie_name :codeql_db

    rake_tasks do
      load File.expand_path("../tasks/codeql_db.rake", __dir__)
    end

    initializer "codeql_db.configure" do |app|
      # Set default configuration for Rails applications
      CodeqlDb.configure do |config|
        config.source_root = Rails.root.to_s if defined?(Rails.root)
        config.default_database_path = Rails.root.join("tmp", "codeql_db").to_s if defined?(Rails.root)
        
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

