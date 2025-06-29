# frozen_string_literal: true

# Only require if not already loaded
unless defined?(CodeqlDb)
  require_relative "../codeql_db"
end

namespace :codeql_db do
  desc "Create a CodeQL database for the current project"
  task :create, [:source_path, :database_path] => :environment do |_task, args|
    source_path = args[:source_path] || "."
    database_path = args[:database_path]
    
    puts "Creating CodeQL database..."
    puts "Source path: #{File.expand_path(source_path)}"
    puts "Database path: #{database_path || 'default'}"
    
    begin
      # Configure CodeQL DB
      CodeqlDb.configure do |config|
        config.verbose = ENV["VERBOSE"] == "true"
        config.threads = ENV["THREADS"]&.to_i || config.threads
        config.ram = ENV["RAM"]&.to_i || config.ram
        config.source_root = source_path
      end

      # Create the database
      options = {
        overwrite: ENV["OVERWRITE"] == "true",
        verbose: CodeqlDb.configuration.verbose
      }

      result = CodeqlDb.create_database(source_path, database_path, options)
      
      puts "\n✓ Database created successfully!"
      puts "  Database path: #{result[:database_path]}"
      puts "  Ruby files: #{result[:ruby_files_count]}"
      puts "  Gemfiles: #{result[:gemfiles_count]}"
      puts "  Created at: #{result[:creation_time]}"
      
    rescue CodeqlDb::Error => e
      puts "\n✗ Failed to create database: #{e.message}"
      exit 1
    rescue => e
      puts "\n✗ Unexpected error: #{e.message}"
      puts e.backtrace.first(5).join("\n") if ENV["DEBUG"]
      exit 1
    end
  end

  desc "List files in a CodeQL database"
  task :list, [:database_path] => :environment do |_task, args|
    database_path = args[:database_path] || "./codeql_db"
    
    puts "Listing files in CodeQL database..."
    puts "Database path: #{File.expand_path(database_path)}"
    
    begin
      CodeqlDb.configure do |config|
        config.verbose = ENV["VERBOSE"] == "true"
      end

      options = {
        include_file_list: ENV["INCLUDE_FILES"] == "true",
        include_stats: ENV["INCLUDE_STATS"] == "true"
      }

      result = CodeqlDb.list_files(database_path, options)
      
      puts "\n📊 Database Information:"
      puts "  Source path: #{result[:source_path]}"
      puts "  Total files: #{result[:total_files]}"
      puts "  Gemfiles: #{result[:gemfiles_count]}"
      puts "  Created: #{result[:creation_time]}"
      
      if options[:include_stats] && result[:statistics]
        puts "\n📈 File Statistics:"
        result[:statistics][:file_types].each do |ext, count|
          puts "  #{ext}: #{count} files"
        end
      end
      
      if options[:include_file_list] && result[:files]
        puts "\n📁 Ruby Files (first 20):"
        result[:files].first(20).each do |file|
          puts "  #{file}"
        end
        puts "  ... and #{[result[:files].count - 20, 0].max} more" if result[:files].count > 20
      end
      
    rescue CodeqlDb::Error => e
      puts "\n✗ Failed to list files: #{e.message}"
      exit 1
    rescue => e
      puts "\n✗ Unexpected error: #{e.message}"
      exit 1
    end
  end

  desc "Analyze a CodeQL database and generate statistics"
  task :analyze, [:database_path] => :environment do |_task, args|
    database_path = args[:database_path] || "./codeql_db"
    
    puts "Analyzing CodeQL database..."
    puts "Database path: #{File.expand_path(database_path)}"
    
    begin
      CodeqlDb.configure do |config|
        config.verbose = ENV["VERBOSE"] == "true"
      end

      result = CodeqlDb.analyze_database(database_path)
      
      puts "\n📊 Analysis Results:"
      puts "  Analysis time: #{result[:analysis_time]}"
      
      basic_stats = result[:basic_stats]
      puts "\n📈 Basic Statistics:"
      puts "  Total files: #{basic_stats[:total_files]}"
      puts "  Ruby files: #{basic_stats[:ruby_files]}"
      puts "  Gemfiles: #{basic_stats[:gemfiles]}"
      puts "  Database size: #{basic_stats[:database_size][:human_readable]}"
      
      file_analysis = result[:file_analysis]
      puts "\n📁 File Type Distribution:"
      file_analysis[:file_types].each do |ext, count|
        puts "  #{ext}: #{count} files"
      end
      
      puts "\n📂 Top Directories by File Count:"
      file_analysis[:directory_distribution].first(10).each do |dir, count|
        puts "  #{dir}: #{count} files"
      end
      
      puts "\n📄 Largest Files:"
      file_analysis[:largest_files].first(5).each do |file_info|
        size_mb = (file_info[:size] / 1024.0 / 1024.0).round(2)
        puts "  #{File.basename(file_info[:path])}: #{size_mb} MB"
      end
      
      summary = result[:summary]
      puts "\n📋 Summary:"
      puts "  Primary language: #{summary[:primary_language]}"
      puts "  Most common extension: #{summary[:most_common_extension]}"
      puts "  Largest directory: #{File.basename(summary[:largest_directory] || 'N/A')}"
      
    rescue CodeqlDb::Error => e
      puts "\n✗ Failed to analyze database: #{e.message}"
      exit 1
    rescue => e
      puts "\n✗ Unexpected error: #{e.message}"
      exit 1
    end
  end

  desc "Delete a CodeQL database"
  task :delete, [:database_path] => :environment do |_task, args|
    database_path = args[:database_path] || "./codeql_db"
    
    puts "Deleting CodeQL database..."
    puts "Database path: #{File.expand_path(database_path)}"
    
    # Confirmation prompt
    unless ENV["FORCE"] == "true"
      print "Are you sure you want to delete this database? (y/N): "
      confirmation = STDIN.gets.chomp.downcase
      unless confirmation == "y" || confirmation == "yes"
        puts "Deletion cancelled."
        exit 0
      end
    end
    
    begin
      CodeqlDb.configure do |config|
        config.verbose = ENV["VERBOSE"] == "true"
      end

      manager = CodeqlDb::Database::Manager.new(CodeqlDb.configuration)
      result = manager.delete(database_path)
      
      puts "\n✓ Database deleted successfully!"
      puts "  Path: #{result[:path]}"
      
    rescue CodeqlDb::Error => e
      puts "\n✗ Failed to delete database: #{e.message}"
      exit 1
    rescue => e
      puts "\n✗ Unexpected error: #{e.message}"
      exit 1
    end
  end

  desc "Show information about a CodeQL database"
  task :info, [:database_path] => :environment do |_task, args|
    database_path = args[:database_path] || "./codeql_db"
    
    puts "Getting CodeQL database information..."
    puts "Database path: #{File.expand_path(database_path)}"
    
    begin
      CodeqlDb.configure do |config|
        config.verbose = ENV["VERBOSE"] == "true"
      end

      manager = CodeqlDb::Database::Manager.new(CodeqlDb.configuration)
      result = manager.info(database_path)
      
      puts "\n📊 Database Information:"
      puts "  Path: #{result[:database_path]}"
      puts "  Size: #{result[:size][:human_readable]} (#{result[:size][:bytes]} bytes)"
      
      metadata = result[:metadata]
      if metadata && !metadata.empty?
        puts "\n📋 Metadata:"
        puts "  Source path: #{metadata[:source_path]}"
        puts "  Creation time: #{metadata[:creation_time]}"
        puts "  Ruby files: #{metadata[:ruby_files]&.count || 0}"
        puts "  Gemfiles: #{metadata[:gemfiles]&.count || 0}"
        
        if metadata[:config]
          puts "\n⚙️  Configuration:"
          puts "  Language: #{metadata[:config][:language]}"
          puts "  Threads: #{metadata[:config][:threads]}"
          puts "  RAM: #{metadata[:config][:ram]}MB"
          puts "  Build mode: #{metadata[:config][:build_mode]}"
        end
      end
      
    rescue CodeqlDb::Error => e
      puts "\n✗ Failed to get database info: #{e.message}"
      exit 1
    rescue => e
      puts "\n✗ Unexpected error: #{e.message}"
      exit 1
    end
  end

  desc "Show help for CodeQL DB tasks"
  task :help do
    puts <<~HELP
      CodeQL DB Rake Tasks
      ====================
      
      Available tasks:
      
      rake codeql_db:create[source_path,database_path]
        Create a new CodeQL database
        Environment variables:
          VERBOSE=true     - Enable verbose output
          THREADS=N        - Number of threads to use
          RAM=N            - RAM in MB to allocate
          OVERWRITE=true   - Overwrite existing database
      
      rake codeql_db:list[database_path]
        List files in a CodeQL database
        Environment variables:
          INCLUDE_FILES=true  - Include file list in output
          INCLUDE_STATS=true  - Include file statistics
      
      rake codeql_db:analyze[database_path]
        Analyze database and generate statistics
      
      rake codeql_db:info[database_path]
        Show detailed database information
      
      rake codeql_db:delete[database_path]
        Delete a CodeQL database
        Environment variables:
          FORCE=true       - Skip confirmation prompt
      
      Examples:
        rake codeql_db:create
        rake codeql_db:create[.,my_database]
        rake codeql_db:list[my_database] INCLUDE_FILES=true
        rake codeql_db:analyze[my_database]
        rake codeql_db:delete[my_database] FORCE=true
    HELP
  end
end

# Fallback task for environments without Rails
unless defined?(Rails)
  task :environment do
    # No-op for non-Rails environments
  end
end

