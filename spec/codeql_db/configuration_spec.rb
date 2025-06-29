# frozen_string_literal: true

RSpec.describe CodeqlDb::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.codeql_cli_path).to eq("codeql")
      expect(config.default_database_path).to eq("./codeql_db")
      expect(config.source_root).to eq(".")
      expect(config.language).to eq("ruby")
      expect(config.threads).to eq(1)
      expect(config.ram).to eq(2048)
      expect(config.build_mode).to eq("none")
      expect(config.include_gemfiles).to be true
      expect(config.verbose).to be false
      expect(config.exclude_patterns).to include(".git", "node_modules", "vendor/bundle")
    end
  end

  describe "#validate!" do
    context "with valid configuration" do
      before do
        allow(config).to receive(:cli_available?).and_return(true)
        allow(config).to receive(:valid_language?).and_return(true)
      end

      it "does not raise an error" do
        expect { config.validate! }.not_to raise_error
      end
    end

    context "with invalid language" do
      before do
        allow(config).to receive(:cli_available?).and_return(true)
        config.language = "invalid_language"
      end

      it "raises a configuration error" do
        expect { config.validate! }.to raise_error(CodeqlDb::ConfigurationError, /Unsupported language/)
      end
    end

    context "with unavailable CLI" do
      before do
        allow(config).to receive(:cli_available?).and_return(false)
      end

      it "raises a configuration error" do
        expect { config.validate! }.to raise_error(CodeqlDb::ConfigurationError, /CodeQL CLI not found/)
      end
    end

    context "with invalid threads" do
      it "raises an error for zero threads" do
        config.threads = 0
        expect { config.validate! }.to raise_error(CodeqlDb::ConfigurationError, /Threads must be positive/)
      end

      it "raises an error for negative threads" do
        config.threads = -1
        expect { config.validate! }.to raise_error(CodeqlDb::ConfigurationError, /Threads must be positive/)
      end
    end

    context "with invalid RAM" do
      it "raises an error for insufficient RAM" do
        config.ram = 100
        expect { config.validate! }.to raise_error(CodeqlDb::ConfigurationError, /RAM must be at least 512 MB/)
      end
    end
  end

  describe "#cli_available?" do
    context "when CLI is in PATH" do
      before do
        allow(config).to receive(:`).with("which codeql 2>/dev/null").and_return("/usr/local/bin/codeql\n")
        allow($?).to receive(:success?).and_return(true)
      end

      it "returns true" do
        expect(config.cli_available?).to be true
      end
    end

    context "when CLI is not in PATH" do
      before do
        allow(config).to receive(:`).with("which codeql 2>/dev/null").and_return("")
        allow($?).to receive(:success?).and_return(false)
      end

      it "returns false" do
        expect(config.cli_available?).to be false
      end
    end

    context "with custom CLI path" do
      before do
        config.codeql_cli_path = "/custom/path/codeql"
      end

      context "when custom path exists" do
        before do
          allow(File).to receive(:executable?).with("/custom/path/codeql").and_return(true)
        end

        it "returns true" do
          expect(config.cli_available?).to be true
        end
      end

      context "when custom path does not exist" do
        before do
          allow(File).to receive(:executable?).with("/custom/path/codeql").and_return(false)
        end

        it "returns false" do
          expect(config.cli_available?).to be false
        end
      end
    end
  end

  describe "#valid_language?" do
    it "returns true for ruby" do
      config.language = "ruby"
      expect(config.valid_language?).to be true
    end

    it "returns true for other supported languages" do
      %w[cpp csharp go java javascript python].each do |lang|
        config.language = lang
        expect(config.valid_language?).to be true
      end
    end

    it "returns false for unsupported languages" do
      config.language = "unsupported"
      expect(config.valid_language?).to be false
    end
  end

  describe "#database_path" do
    it "returns provided path when given" do
      expect(config.database_path("custom/path")).to eq("custom/path")
    end

    it "returns default path when nil provided" do
      expect(config.database_path(nil)).to eq("./codeql_db")
    end

    it "returns default path when empty string provided" do
      expect(config.database_path("")).to eq("./codeql_db")
    end
  end

  describe "attribute accessors" do
    it "allows setting and getting codeql_cli_path" do
      config.codeql_cli_path = "/custom/codeql"
      expect(config.codeql_cli_path).to eq("/custom/codeql")
    end

    it "allows setting and getting threads" do
      config.threads = 4
      expect(config.threads).to eq(4)
    end

    it "allows setting and getting ram" do
      config.ram = 4096
      expect(config.ram).to eq(4096)
    end

    it "allows setting and getting verbose" do
      config.verbose = true
      expect(config.verbose).to be true
    end

    it "allows setting and getting exclude_patterns" do
      patterns = %w[custom exclude patterns]
      config.exclude_patterns = patterns
      expect(config.exclude_patterns).to eq(patterns)
    end
  end

  describe "exclude patterns" do
    it "includes common exclusion patterns by default" do
      expect(config.exclude_patterns).to include(
        ".git", "node_modules", "vendor/bundle", "tmp", "log", 
        "coverage", ".bundle", "public/assets", "storage"
      )
    end

    it "allows adding custom exclusion patterns" do
      config.exclude_patterns << "custom_exclude"
      expect(config.exclude_patterns).to include("custom_exclude")
    end
  end

  describe "configuration validation edge cases" do
    before do
      allow(config).to receive(:cli_available?).and_return(true)
      allow(config).to receive(:valid_language?).and_return(true)
    end

    it "accepts minimum valid RAM" do
      config.ram = 512
      expect { config.validate! }.not_to raise_error
    end

    it "accepts single thread" do
      config.threads = 1
      expect { config.validate! }.not_to raise_error
    end

    it "accepts high thread count" do
      config.threads = 16
      expect { config.validate! }.not_to raise_error
    end

    it "accepts high RAM allocation" do
      config.ram = 16384
      expect { config.validate! }.not_to raise_error
    end
  end
end

