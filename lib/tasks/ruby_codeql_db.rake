# frozen_string_literal: true

# Only require if not already loaded
unless defined?(RubyCodeqlDb)
  require_relative "../ruby_codeql_db"
end

namespace :ruby_codeql_db do
  desc "Create a RubyCodeqlDb database"
  task :create, [:source_path, :database_path] => :environment do |_, args|
    # Configure RubyCodeqlDb
    RubyCodeqlDb.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
      config.threads = ENV['THREADS']&.to_i || 2
      config.ram = ENV['RAM']&.to_i || 2048
    end

    source_path = args[:source_path] || "."
    database_path = args[:database_path] || "./ruby_codeql_db"
    options = {
      overwrite: ENV['OVERWRITE'] == 'true',
      verbose: RubyCodeqlDb.configuration.verbose
    }

    puts "Creating RubyCodeqlDb database..."
    puts "Source: #{source_path}"
    puts "Database: #{database_path}"

    begin
      result = RubyCodeqlDb.create_database(source_path, database_path, options)
      puts "✓ Database created successfully!"
      puts "  Path: #{result[:database_path]}"
      puts "  Ruby files: #{result[:ruby_files_count]}"
      puts "  Gemfiles: #{result[:gemfiles_count]}"
    rescue RubyCodeqlDb::Error => e
      puts "✗ Failed to create database: #{e.message}"
      exit 1
    end
  end

  desc "List files in a RubyCodeqlDb database"
  task :list, [:database_path] => :environment do |_, args|
    # Configure RubyCodeqlDb
    RubyCodeqlDb.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end

    database_path = args[:database_path] || "./ruby_codeql_db"
    options = {
      include_file_list: ENV['INCLUDE_FILES'] == 'true',
      include_stats: ENV['INCLUDE_STATS'] == 'true'
    }

    puts "Listing files in RubyCodeqlDb database..."
    puts "Database: #{database_path}"

    begin
      result = RubyCodeqlDb.list_files(database_path, options)
      puts "✓ Database information retrieved!"
      puts "  Source: #{result[:source_path]}"
      puts "  Total files: #{result[:total_files]}"
      puts "  Gemfiles: #{result[:gemfiles_count]}"
      puts "  Created: #{result[:creation_time]}"

      if options[:include_stats] && result[:statistics]
        puts "\nFile types:"
        result[:statistics][:file_types].each do |ext, count|
          puts "  #{ext}: #{count} files"
        end
      end
    rescue RubyCodeqlDb::Error => e
      puts "✗ Failed to list files: #{e.message}"
      exit 1
    end
  end

  desc "Analyze a RubyCodeqlDb database"
  task :analyze, [:database_path] => :environment do |_, args|
    # Configure RubyCodeqlDb
    RubyCodeqlDb.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end

    database_path = args[:database_path] || "./ruby_codeql_db"

    puts "Analyzing RubyCodeqlDb database..."
    puts "Database: #{database_path}"

    begin
      result = RubyCodeqlDb.analyze_database(database_path)
      puts "✓ Analysis completed!"

      summary = result[:summary]
      puts "\nSummary:"
      puts "  Total files: #{summary[:total_files]}"
      puts "  Lines of code: #{summary[:lines_of_code]}"
      puts "  Comment ratio: #{summary[:comment_ratio]}"
      puts "  Total methods: #{summary[:total_methods]}"
      puts "  Total classes: #{summary[:total_classes]}"
      puts "  Complexity score: #{summary[:complexity_score]}"
    rescue RubyCodeqlDb::Error => e
      puts "✗ Failed to analyze database: #{e.message}"
      exit 1
    end
  end

  desc "Show database information"
  task :info, [:database_path] => :environment do |_, args|
    # Configure RubyCodeqlDb
    RubyCodeqlDb.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end

    database_path = args[:database_path] || "./ruby_codeql_db"

    puts "Getting RubyCodeqlDb database information..."
    puts "Database: #{database_path}"

    begin
      manager = RubyCodeqlDb::Database::Manager.new(RubyCodeqlDb.configuration)
      result = manager.info(database_path)

      puts "✓ Database information retrieved!"
      puts "  Path: #{result[:database_path]}"
      puts "  Size: #{result[:size][:human_readable]}"

      if result[:metadata] && !result[:metadata].empty?
        puts "  Source: #{result[:metadata][:source_path]}"
        puts "  Created: #{result[:metadata][:creation_time]}"
      end
    rescue RubyCodeqlDb::Error => e
      puts "✗ Failed to get database info: #{e.message}"
      exit 1
    end
  end

  desc "Delete a RubyCodeqlDb database"
  task :delete, [:database_path] => :environment do |_, args|
    # Configure RubyCodeqlDb
    RubyCodeqlDb.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end

    database_path = args[:database_path] || "./ruby_codeql_db"
    force = ENV['FORCE'] == 'true'

    puts "Deleting RubyCodeqlDb database..."
    puts "Database: #{database_path}"

    unless force
      print "Are you sure? (y/N): "
      confirmation = STDIN.gets.chomp.downcase
      unless confirmation == "y" || confirmation == "yes"
        puts "Deletion cancelled."
        exit 0
      end
    end

    begin
      manager = RubyCodeqlDb::Database::Manager.new(RubyCodeqlDb.configuration)
      result = manager.delete(database_path)
      puts "✓ Database deleted successfully!"
      puts "  Path: #{result[:path]}"
    rescue RubyCodeqlDb::Error => e
      puts "✗ Failed to delete database: #{e.message}"
      exit 1
    end
  end

  desc "Show help for RubyCodeqlDb tasks"
  task :help do
    puts <<~HELP
      RubyCodeqlDb Rake Tasks

      Available tasks:
        rake ruby_codeql_db:create[source_path,database_path]  # Create a RubyCodeqlDb database
        rake ruby_codeql_db:list[database_path]                # List files in database
        rake ruby_codeql_db:analyze[database_path]             # Analyze database
        rake ruby_codeql_db:info[database_path]                # Show database info
        rake ruby_codeql_db:delete[database_path]              # Delete database
        rake ruby_codeql_db:help                               # Show this help

      Environment variables:
        VERBOSE=true          # Enable verbose output
        THREADS=4             # Number of threads
        RAM=4096              # RAM in MB
        OVERWRITE=true        # Overwrite existing database
        INCLUDE_FILES=true    # Include file list in output
        INCLUDE_STATS=true    # Include statistics in output
        FORCE=true            # Skip confirmation for delete

      Examples:
        rake ruby_codeql_db:create
        rake ruby_codeql_db:create[.,my_database]
        rake ruby_codeql_db:list[my_database] INCLUDE_FILES=true
        rake ruby_codeql_db:analyze[my_database]
        rake ruby_codeql_db:delete[my_database] FORCE=true
    HELP
  end
end

# Fallback task for environments without Rails
unless defined?(Rails)
  task :environment do
    # No-op for non-Rails environments
  end
end

