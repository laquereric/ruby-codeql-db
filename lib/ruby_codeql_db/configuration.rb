# frozen_string_literal: true

module RubyCodeqlDb
  # Configuration class for CodeQL database operations
  class Configuration
    attr_accessor :codeql_cli_path, :default_database_path, :source_root,
                  :language, :threads, :ram, :build_mode, :include_gemfiles,
                  :exclude_patterns, :verbose

    def initialize
      @codeql_cli_path = find_codeql_cli || "codeql"
      @default_database_path = "./ruby_codeql_db"
      @source_root = "."
      @language = "ruby"
      @threads = 1
      @ram = 2048
      @build_mode = "none"
      @include_gemfiles = true
      @exclude_patterns = %w[
        .git
        node_modules
        vendor/bundle
        tmp
        log
        coverage
        .bundle
      ]
      @verbose = false
    end

    def validate!
      raise ConfigurationError, "CodeQL CLI not found at: #{codeql_cli_path}" unless cli_available?
      raise ConfigurationError, "Source root does not exist: #{source_root}" unless Dir.exist?(source_root)
      raise ConfigurationError, "Invalid language: #{language}" unless valid_language?
      raise ConfigurationError, "Invalid threads value: #{threads}" unless threads.is_a?(Integer) && threads > 0
      raise ConfigurationError, "Invalid RAM value: #{ram}" unless ram.is_a?(Integer) && ram > 0
    end

    def cli_available?
      system("#{codeql_cli_path} version > /dev/null 2>&1")
    end

    def valid_language?
      %w[ruby java javascript python cpp csharp go].include?(language.to_s.downcase)
    end

    def database_path(custom_path = nil)
      custom_path || default_database_path
    end

    def cli_command_base
      [codeql_cli_path]
    end

    def create_command_options
      options = []
      options << "--language=#{language}"
      options << "--source-root=#{source_root}"
      options << "--threads=#{threads}"
      options << "--ram=#{ram}"
      options << "--build-mode=#{build_mode}" if build_mode != "none"
      options
    end

    def exclude_patterns_for_find
      exclude_patterns.map { |pattern| "-not -path '*/#{pattern}/*'" }.join(" ")
    end

    private

    def find_codeql_cli
      # Try common installation paths
      paths = [
        "/usr/local/bin/codeql",
        "/opt/codeql/codeql",
        "#{ENV['HOME']}/codeql/codeql",
        "codeql"
      ]

      paths.find { |path| File.executable?(path) || system("which #{path} > /dev/null 2>&1") }
    end
  end
end

