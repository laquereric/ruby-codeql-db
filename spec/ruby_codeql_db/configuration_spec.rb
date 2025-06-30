# frozen_string_literal: true

RSpec.describe RubyCodeqlDb::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.default_database_path).to eq("./ruby_codeql_db")
      expect(config.source_root).to eq(".")
      expect(config.language).to eq("ruby")
      expect(config.threads).to eq(1)
      expect(config.ram).to eq(2048)
      expect(config.build_mode).to eq("none")
      expect(config.include_gemfiles).to be true
      expect(config.verbose).to be false
    end

    it "sets default exclude patterns" do
      expected_patterns = %w[
        .git
        node_modules
        vendor/bundle
        tmp
        log
        coverage
        .bundle
      ]
      expect(config.exclude_patterns).to eq(expected_patterns)
    end

    it "attempts to find CodeQL CLI" do
      expect(config.codeql_cli_path).to be_a(String)
    end
  end

  describe "#validate!" do
    before do
      mock_codeql_cli_available
    end

    it "raises no error with valid configuration" do
      expect { config.validate! }.not_to raise_error
    end

    it "raises error when CodeQL CLI is not available" do
      mock_codeql_cli_unavailable
      expect { config.validate! }.to raise_error(RubyCodeqlDb::ConfigurationError, /CodeQL CLI not found/)
    end

    it "raises error when source root does not exist" do
      config.source_root = "/nonexistent/path"
      expect { config.validate! }.to raise_error(RubyCodeqlDb::ConfigurationError, /Source root does not exist/)
    end

    it "raises error with invalid language" do
      config.language = "invalid_language"
      expect { config.validate! }.to raise_error(RubyCodeqlDb::ConfigurationError, /Invalid language/)
    end

    it "raises error with invalid threads value" do
      config.threads = 0
      expect { config.validate! }.to raise_error(RubyCodeqlDb::ConfigurationError, /Invalid threads value/)
    end

    it "raises error with invalid RAM value" do
      config.ram = -1
      expect { config.validate! }.to raise_error(RubyCodeqlDb::ConfigurationError, /Invalid RAM value/)
    end
  end

  describe "#cli_available?" do
    it "returns true when CLI is available" do
      mock_codeql_cli_available
      expect(config.cli_available?).to be true
    end

    it "returns false when CLI is not available" do
      mock_codeql_cli_unavailable
      expect(config.cli_available?).to be false
    end
  end

  describe "#valid_language?" do
    it "returns true for supported languages" do
      %w[ruby java javascript python cpp csharp go].each do |language|
        config.language = language
        expect(config.valid_language?).to be true
      end
    end

    it "returns false for unsupported languages" do
      %w[invalid php perl].each do |language|
        config.language = language
        expect(config.valid_language?).to be false
      end
    end

    it "handles case insensitive language names" do
      config.language = "RUBY"
      expect(config.valid_language?).to be true
    end
  end

  describe "#database_path" do
    it "returns custom path when provided" do
      custom_path = "/custom/path"
      expect(config.database_path(custom_path)).to eq(custom_path)
    end

    it "returns default path when no custom path provided" do
      expect(config.database_path(nil)).to eq("./ruby_codeql_db")
    end

    it "returns default path when empty string provided" do
      expect(config.database_path("")).to eq("./ruby_codeql_db")
    end
  end

  describe "#cli_command_base" do
    it "returns array with CLI path" do
      expect(config.cli_command_base).to eq([config.codeql_cli_path])
    end
  end

  describe "#create_command_options" do
    it "returns array of command options" do
      options = config.create_command_options
      
      expect(options).to include("--language=ruby")
      expect(options).to include("--source-root=.")
      expect(options).to include("--threads=1")
      expect(options).to include("--ram=2048")
    end

    it "includes build mode when not none" do
      config.build_mode = "make"
      options = config.create_command_options
      expect(options).to include("--build-mode=make")
    end

    it "does not include build mode when none" do
      config.build_mode = "none"
      options = config.create_command_options
      expect(options).not_to include(/--build-mode/)
    end
  end

  describe "#exclude_patterns_for_find" do
    it "formats exclude patterns for find command" do
      config.exclude_patterns = %w[.git node_modules]
      result = config.exclude_patterns_for_find
      
      expect(result).to include("-not -path '*/#{config.exclude_patterns[0]}/*'")
      expect(result).to include("-not -path '*/#{config.exclude_patterns[1]}/*'")
    end
  end

  describe "attribute accessors" do
    it "allows setting and getting all attributes" do
      config.codeql_cli_path = "/custom/codeql"
      config.default_database_path = "/custom/db"
      config.source_root = "/custom/source"
      config.language = "java"
      config.threads = 4
      config.ram = 4096
      config.build_mode = "make"
      config.include_gemfiles = false
      config.exclude_patterns = %w[custom1 custom2]
      config.verbose = true

      expect(config.codeql_cli_path).to eq("/custom/codeql")
      expect(config.default_database_path).to eq("/custom/db")
      expect(config.source_root).to eq("/custom/source")
      expect(config.language).to eq("java")
      expect(config.threads).to eq(4)
      expect(config.ram).to eq(4096)
      expect(config.build_mode).to eq("make")
      expect(config.include_gemfiles).to be false
      expect(config.exclude_patterns).to eq(%w[custom1 custom2])
      expect(config.verbose).to be true
    end
  end
end


