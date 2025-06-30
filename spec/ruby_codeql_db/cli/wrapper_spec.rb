# frozen_string_literal: true

RSpec.describe CodeqlDb::CLI::Wrapper do
  let(:config) { CodeqlDb::Configuration.new }
  let(:wrapper) { described_class.new(config) }

  before do
    mock_codeql_cli_available
  end

  describe "#initialize" do
    it "accepts a configuration object" do
      expect(wrapper.config).to eq(config)
    end

    it "validates configuration on initialization" do
      expect(config).to receive(:validate!)
      described_class.new(config)
    end
  end

  describe "#create_database" do
    let(:source_path) { "/path/to/source" }
    let(:database_path) { "/path/to/database" }
    let(:options) { { language: "ruby", threads: 2, ram: 2048 } }

    context "when command succeeds" do
      before do
        allow(wrapper).to receive(:run_command).and_return([true, "Database created successfully", ""])
      end

      it "returns true" do
        result = wrapper.create_database(source_path, database_path, options)
        expect(result).to be true
      end

      it "calls run_command with correct arguments" do
        expected_command = [
          config.codeql_cli_path,
          "database", "create",
          database_path,
          "--language=ruby",
          "--source-root=#{source_path}",
          "--threads=2",
          "--ram=2048"
        ]

        expect(wrapper).to receive(:run_command).with(expected_command, anything)
        wrapper.create_database(source_path, database_path, options)
      end

      it "includes overwrite flag when specified" do
        options[:overwrite] = true
        expected_command = [
          config.codeql_cli_path,
          "database", "create",
          database_path,
          "--language=ruby",
          "--source-root=#{source_path}",
          "--threads=2",
          "--ram=2048",
          "--overwrite"
        ]

        expect(wrapper).to receive(:run_command).with(expected_command, anything)
        wrapper.create_database(source_path, database_path, options)
      end

      it "includes extractor options when specified" do
        options[:extractor_options] = { "ruby.extraction.timeout" => "300" }
        
        expect(wrapper).to receive(:run_command) do |command, _|
          expect(command).to include("--extractor-option=ruby.extraction.timeout=300")
        end
        
        wrapper.create_database(source_path, database_path, options)
      end
    end

    context "when command fails" do
      before do
        allow(wrapper).to receive(:run_command).and_return([false, "", "Error creating database"])
      end

      it "raises CLIError" do
        expect {
          wrapper.create_database(source_path, database_path, options)
        }.to raise_error(CodeqlDb::CLIError, /Failed to create database/)
      end
    end

    context "with verbose output" do
      before do
        config.verbose = true
        allow(wrapper).to receive(:run_command).and_return([true, "Verbose output", ""])
        allow(wrapper).to receive(:puts)
      end

      it "outputs command when verbose" do
        expect(wrapper).to receive(:puts).with(/Running CodeQL command/)
        wrapper.create_database(source_path, database_path, options)
      end
    end
  end

  describe "#list_database_files" do
    let(:database_path) { "/path/to/database" }

    context "when command succeeds" do
      let(:output) do
        "file1.rb\nfile2.rb\nGemfile\ntest.gemspec\n"
      end

      before do
        allow(wrapper).to receive(:run_command).and_return([true, output, ""])
      end

      it "returns array of files" do
        result = wrapper.list_database_files(database_path)
        expect(result).to eq(["file1.rb", "file2.rb", "Gemfile", "test.gemspec"])
      end
    end

    context "when command fails" do
      before do
        allow(wrapper).to receive(:run_command).and_return([false, "", "Database not found"])
      end

      it "raises CLIError" do
        expect {
          wrapper.list_database_files(database_path)
        }.to raise_error(CodeqlDb::CLIError, /Failed to list database files/)
      end
    end

    context "with empty output" do
      before do
        allow(wrapper).to receive(:run_command).and_return([true, "", ""])
      end

      it "returns empty array" do
        result = wrapper.list_database_files(database_path)
        expect(result).to eq([])
      end
    end
  end

  describe "#database_exists?" do
    let(:database_path) { "/path/to/database" }

    context "when database exists" do
      before do
        allow(wrapper).to receive(:run_command).and_return([true, "Database info", ""])
      end

      it "returns true" do
        result = wrapper.database_exists?(database_path)
        expect(result).to be true
      end
    end

    context "when database does not exist" do
      before do
        allow(wrapper).to receive(:run_command).and_return([false, "", "Database not found"])
      end

      it "returns false" do
        result = wrapper.database_exists?(database_path)
        expect(result).to be false
      end
    end
  end

  describe "#run_query" do
    let(:database_path) { "/path/to/database" }
    let(:query_path) { "/path/to/query.ql" }

    context "when query succeeds" do
      let(:output) { "query,result\nvalue1,value2\n" }

      before do
        allow(wrapper).to receive(:run_command).and_return([true, output, ""])
      end

      it "returns query results" do
        result = wrapper.run_query(database_path, query_path)
        expect(result).to eq(output)
      end

      it "uses specified output format" do
        expected_command = [
          config.codeql_cli_path,
          "database", "analyze",
          database_path,
          query_path,
          "--format=json"
        ]

        expect(wrapper).to receive(:run_command).with(expected_command, anything)
        wrapper.run_query(database_path, query_path, "json")
      end
    end

    context "when query fails" do
      before do
        allow(wrapper).to receive(:run_command).and_return([false, "", "Query execution failed"])
      end

      it "raises CLIError" do
        expect {
          wrapper.run_query(database_path, query_path)
        }.to raise_error(CodeqlDb::CLIError, /Failed to run query/)
      end
    end
  end

  describe "#version" do
    context "when command succeeds" do
      before do
        allow(wrapper).to receive(:run_command).and_return([true, "CodeQL command-line toolchain release 2.15.0", ""])
      end

      it "returns version string" do
        result = wrapper.version
        expect(result).to eq("CodeQL command-line toolchain release 2.15.0")
      end
    end

    context "when command fails" do
      before do
        allow(wrapper).to receive(:run_command).and_return([false, "", "Command not found"])
      end

      it "raises CLIError" do
        expect {
          wrapper.version
        }.to raise_error(CodeqlDb::CLIError, /Failed to get CodeQL version/)
      end
    end
  end

  describe "private methods" do
    describe "#run_command" do
      let(:command) { ["echo", "test"] }
      let(:options) { { timeout: 30 } }

      context "when command succeeds" do
        it "returns success status and output" do
          success, stdout, stderr = wrapper.send(:run_command, command, options)
          expect(success).to be true
          expect(stdout.strip).to eq("test")
          expect(stderr).to be_empty
        end
      end

      context "when command fails" do
        let(:command) { ["false"] }

        it "returns failure status" do
          success, stdout, stderr = wrapper.send(:run_command, command, options)
          expect(success).to be false
        end
      end

      context "when command times out" do
        let(:command) { ["sleep", "2"] }
        let(:options) { { timeout: 0.1 } }

        it "raises timeout error" do
          expect {
            wrapper.send(:run_command, command, options)
          }.to raise_error(CodeqlDb::CLIError, /Command timed out/)
        end
      end

      context "with verbose output" do
        before do
          config.verbose = true
          allow(wrapper).to receive(:puts)
        end

        it "outputs command when verbose" do
          expect(wrapper).to receive(:puts).with(/Running command/)
          wrapper.send(:run_command, command, options)
        end
      end
    end

    describe "#build_create_command" do
      let(:source_path) { "/source" }
      let(:database_path) { "/database" }
      let(:options) { { language: "ruby", threads: 4, ram: 4096 } }

      it "builds correct command array" do
        command = wrapper.send(:build_create_command, source_path, database_path, options)
        
        expect(command).to include(
          config.codeql_cli_path,
          "database", "create",
          database_path,
          "--language=ruby",
          "--source-root=/source",
          "--threads=4",
          "--ram=4096"
        )
      end

      it "includes overwrite flag when specified" do
        options[:overwrite] = true
        command = wrapper.send(:build_create_command, source_path, database_path, options)
        expect(command).to include("--overwrite")
      end

      it "includes extractor options when specified" do
        options[:extractor_options] = { "ruby.timeout" => "300", "ruby.debug" => "true" }
        command = wrapper.send(:build_create_command, source_path, database_path, options)
        
        expect(command).to include("--extractor-option=ruby.timeout=300")
        expect(command).to include("--extractor-option=ruby.debug=true")
      end
    end

    describe "#escape_shell_arg" do
      it "escapes shell arguments correctly" do
        expect(wrapper.send(:escape_shell_arg, "simple")).to eq("simple")
        expect(wrapper.send(:escape_shell_arg, "with spaces")).to eq("'with spaces'")
        expect(wrapper.send(:escape_shell_arg, "with'quote")).to eq("'with'\\''quote'")
      end
    end
  end

  describe "error handling" do
    context "when CLI is not available" do
      before do
        mock_codeql_cli_unavailable
      end

      it "raises configuration error during initialization" do
        expect {
          described_class.new(config)
        }.to raise_error(CodeqlDb::ConfigurationError)
      end
    end

    context "when command execution fails" do
      before do
        allow(wrapper).to receive(:run_command).and_raise(StandardError, "Execution failed")
      end

      it "wraps standard errors in CLIError" do
        expect {
          wrapper.create_database("/source", "/database")
        }.to raise_error(CodeqlDb::CLIError, /Execution failed/)
      end
    end
  end
end

