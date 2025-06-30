# frozen_string_literal: true

require "open3"
require "json"

module RubyCodeqlDb
  module CLI
    # Wrapper class for CodeQL CLI operations
    class Wrapper
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def create_database(source_path, database_path, options = {})
        validate_cli_availability!

        command = build_create_command(source_path, database_path, options)
        execute_command(command, "Creating CodeQL database")
      end

      def list_database_files(database_path)
        validate_cli_availability!
        validate_database_exists!(database_path)

        # Use CodeQL CLI to get database info
        command = [config.codeql_cli_path, "database", "info", database_path, "--format=json"]
        result = execute_command(command, "Getting database information")
        
        begin
          JSON.parse(result[:stdout])
        rescue JSON::ParserError => e
          raise CLIError, "Failed to parse database info: #{e.message}"
        end
      end

      def database_exists?(database_path)
        return false unless Dir.exist?(database_path)
        
        # Check for CodeQL database structure
        required_files = %w[codeql-database.yml src.zip]
        required_files.all? { |file| File.exist?(File.join(database_path, file)) }
      end

      def get_database_languages(database_path)
        validate_database_exists!(database_path)
        
        command = [config.codeql_cli_path, "resolve", "languages", "--format=json"]
        result = execute_command(command, "Getting supported languages")
        
        begin
          JSON.parse(result[:stdout])
        rescue JSON::ParserError
          ["ruby"] # fallback
        end
      end

      def run_query(database_path, query_path, output_format = "csv")
        validate_cli_availability!
        validate_database_exists!(database_path)

        command = [
          config.codeql_cli_path,
          "database", "analyze",
          database_path,
          query_path,
          "--format=#{output_format}",
          "--output=-"
        ]

        execute_command(command, "Running CodeQL query")
      end

      def version
        command = [config.codeql_cli_path, "version"]
        result = execute_command(command, "Getting CodeQL version")
        result[:stdout].strip
      end

      private

      def build_create_command(source_path, database_path, options)
        command = [config.codeql_cli_path, "database", "create"]
        command += config.create_command_options
        command += build_additional_options(options)
        command << database_path
        command << "--source-root=#{source_path}"
        command
      end

      def build_additional_options(options)
        opts = []
        opts << "--overwrite" if options[:overwrite]
        opts << "--verbose" if options[:verbose] || config.verbose
        opts << "--command=#{options[:command]}" if options[:command]
        
        if options[:extractor_options]
          options[:extractor_options].each do |key, value|
            opts << "--extractor-option=#{key}=#{value}"
          end
        end

        opts
      end

      def execute_command(command, description)
        log_command(command, description) if config.verbose

        stdout, stderr, status = Open3.capture3(*command)

        result = {
          command: command.join(" "),
          stdout: stdout,
          stderr: stderr,
          status: status,
          success: status.success?
        }

        log_result(result) if config.verbose

        unless result[:success]
          raise CLIError, "#{description} failed: #{stderr.empty? ? stdout : stderr}"
        end

        result
      end

      def validate_cli_availability!
        unless config.cli_available?
          raise CLIError, "CodeQL CLI not available at: #{config.codeql_cli_path}"
        end
      end

      def validate_database_exists!(database_path)
        unless database_exists?(database_path)
          raise DatabaseError, "CodeQL database not found at: #{database_path}"
        end
      end

      def log_command(command, description)
        puts "[CodeQL] #{description}..."
        puts "[CodeQL] Command: #{command.join(' ')}" if config.verbose
      end

      def log_result(result)
        puts "[CodeQL] Exit status: #{result[:status].exitstatus}"
        puts "[CodeQL] STDOUT: #{result[:stdout]}" unless result[:stdout].empty?
        puts "[CodeQL] STDERR: #{result[:stderr]}" unless result[:stderr].empty?
      end
    end
  end
end

