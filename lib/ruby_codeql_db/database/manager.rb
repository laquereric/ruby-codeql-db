# frozen_string_literal: true

require "fileutils"
require "find"

module RubyCodeqlDb
  module Database
    # High-level database management operations
    class Manager
      attr_reader :config, :cli

      def initialize(config)
        @config = config
        @cli = CLI::Wrapper.new(config)
      end

      def create(source_path, database_path = nil, options = {})
        source_path = File.expand_path(source_path)
        database_path = File.expand_path(config.database_path(database_path))

        validate_source_path!(source_path)
        prepare_database_directory!(database_path, options[:overwrite])

        # Scan for Ruby files and Gemfiles
        ruby_files = scan_ruby_files(source_path)
        gemfiles = scan_gemfiles(source_path) if config.include_gemfiles

        puts "Found #{ruby_files.count} Ruby files" if config.verbose
        puts "Found #{gemfiles.count} Gemfiles" if config.verbose && config.include_gemfiles

        # Create the database
        create_options = options.merge(
          source_files: ruby_files,
          gemfiles: gemfiles
        )

        result = cli.create_database(source_path, database_path, create_options)
        
        # Store metadata about the created database
        store_database_metadata(database_path, source_path, ruby_files, gemfiles)

        {
          database_path: database_path,
          source_path: source_path,
          ruby_files_count: ruby_files.count,
          gemfiles_count: gemfiles&.count || 0,
          creation_time: Time.now,
          cli_result: result
        }
      end

      def list_files(database_path, options = {})
        database_path = File.expand_path(database_path)
        
        unless cli.database_exists?(database_path)
          raise DatabaseError, "Database not found: #{database_path}"
        end

        metadata = load_database_metadata(database_path)
        
        files_info = {
          database_path: database_path,
          source_path: metadata[:source_path],
          total_files: metadata[:ruby_files]&.count || 0,
          gemfiles_count: metadata[:gemfiles]&.count || 0,
          creation_time: metadata[:creation_time],
          files: []
        }

        if options[:include_file_list]
          files_info[:files] = metadata[:ruby_files] || []
          files_info[:gemfiles] = metadata[:gemfiles] || []
        end

        if options[:include_stats]
          files_info[:statistics] = calculate_file_statistics(metadata)
        end

        files_info
      end

      def delete(database_path)
        database_path = File.expand_path(database_path)
        
        unless cli.database_exists?(database_path)
          raise DatabaseError, "Database not found: #{database_path}"
        end

        FileUtils.rm_rf(database_path)
        puts "Deleted database: #{database_path}" if config.verbose

        { deleted: true, path: database_path }
      end

      def exists?(database_path)
        cli.database_exists?(File.expand_path(database_path))
      end

      def info(database_path)
        database_path = File.expand_path(database_path)
        
        unless cli.database_exists?(database_path)
          raise DatabaseError, "Database not found: #{database_path}"
        end

        cli_info = cli.list_database_files(database_path)
        metadata = load_database_metadata(database_path)

        {
          database_path: database_path,
          cli_info: cli_info,
          metadata: metadata,
          size: calculate_database_size(database_path)
        }
      end

      private

      def validate_source_path!(source_path)
        unless Dir.exist?(source_path)
          raise DatabaseError, "Source path does not exist: #{source_path}"
        end
      end

      def prepare_database_directory!(database_path, overwrite = false)
        if Dir.exist?(database_path)
          if overwrite
            FileUtils.rm_rf(database_path)
            puts "Removed existing database: #{database_path}" if config.verbose
          else
            raise DatabaseError, "Database already exists: #{database_path}. Use overwrite: true to replace."
          end
        end

        FileUtils.mkdir_p(File.dirname(database_path))
      end

      def scan_ruby_files(source_path)
        ruby_files = []
        
        Find.find(source_path) do |path|
          # Skip excluded directories
          if File.directory?(path)
            dir_name = File.basename(path)
            if config.exclude_patterns.any? { |pattern| dir_name.match?(pattern) }
              Find.prune
              next
            end
          end

          # Include Ruby files
          if File.file?(path) && ruby_file?(path)
            ruby_files << path
          end
        end

        ruby_files.sort
      end

      def scan_gemfiles(source_path)
        gemfiles = []
        
        Find.find(source_path) do |path|
          # Skip excluded directories
          if File.directory?(path)
            dir_name = File.basename(path)
            if config.exclude_patterns.any? { |pattern| dir_name.match?(pattern) }
              Find.prune
              next
            end
          end

          # Include Gemfiles and gemspecs
          if File.file?(path) && gemfile?(path)
            gemfiles << path
          end
        end

        gemfiles.sort
      end

      def ruby_file?(path)
        return true if path.end_with?(".rb")
        return true if path.end_with?(".rake")
        return true if path.end_with?(".gemspec")
        
        # Check for Ruby shebang
        if File.executable?(path) && File.size(path) > 0
          first_line = File.open(path, &:readline).strip rescue ""
          return true if first_line.include?("ruby")
        end

        false
      end

      def gemfile?(path)
        basename = File.basename(path)
        basename == "Gemfile" || 
        basename.start_with?("Gemfile.") ||
        basename.end_with?(".gemspec")
      end

      def store_database_metadata(database_path, source_path, ruby_files, gemfiles)
        metadata = {
          source_path: source_path,
          ruby_files: ruby_files,
          gemfiles: gemfiles,
          creation_time: Time.now.iso8601,
          config: {
            language: config.language,
            threads: config.threads,
            ram: config.ram,
            build_mode: config.build_mode
          }
        }

        metadata_path = File.join(database_path, "ruby_codeql_db_metadata.json")
        File.write(metadata_path, JSON.pretty_generate(metadata))
      end

      def load_database_metadata(database_path)
        metadata_path = File.join(database_path, "ruby_codeql_db_metadata.json")
        
        if File.exist?(metadata_path)
          JSON.parse(File.read(metadata_path), symbolize_names: true)
        else
          {}
        end
      end

      def calculate_file_statistics(metadata)
        ruby_files = metadata[:ruby_files] || []
        gemfiles = metadata[:gemfiles] || []

        stats = {
          total_files: ruby_files.count + gemfiles.count,
          ruby_files: ruby_files.count,
          gemfiles: gemfiles.count,
          file_types: {}
        }

        # Count by file extension
        all_files = ruby_files + gemfiles
        all_files.each do |file|
          ext = File.extname(file).downcase
          ext = "no_extension" if ext.empty?
          stats[:file_types][ext] = (stats[:file_types][ext] || 0) + 1
        end

        stats
      end

      def calculate_database_size(database_path)
        total_size = 0
        
        Find.find(database_path) do |path|
          total_size += File.size(path) if File.file?(path)
        end

        {
          bytes: total_size,
          human_readable: format_bytes(total_size)
        }
      end

      def format_bytes(bytes)
        units = %w[B KB MB GB TB]
        size = bytes.to_f
        unit_index = 0

        while size >= 1024 && unit_index < units.length - 1
          size /= 1024
          unit_index += 1
        end

        "#{size.round(2)} #{units[unit_index]}"
      end
    end
  end
end

