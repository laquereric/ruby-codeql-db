# frozen_string_literal: true

RSpec.describe CodeqlDb do
  it "has a version number" do
    expect(CodeqlDb::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields configuration object" do
      expect { |b| CodeqlDb.configure(&b) }.to yield_with_args(CodeqlDb::Configuration)
    end

    it "allows setting configuration options" do
      CodeqlDb.configure do |config|
        config.verbose = true
        config.threads = 4
        config.ram = 4096
      end

      expect(CodeqlDb.configuration.verbose).to be true
      expect(CodeqlDb.configuration.threads).to eq(4)
      expect(CodeqlDb.configuration.ram).to eq(4096)
    end
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(CodeqlDb.configuration).to be_a(CodeqlDb::Configuration)
    end

    it "returns the same instance on multiple calls" do
      config1 = CodeqlDb.configuration
      config2 = CodeqlDb.configuration
      expect(config1).to be(config2)
    end
  end

  describe ".create_database" do
    let(:source_path) { temp_dir }
    let(:database_path) { File.join(temp_dir, "test_database") }
    let(:manager) { instance_double(CodeqlDb::Database::Manager) }
    let(:create_result) do
      {
        database_path: database_path,
        source_path: source_path,
        ruby_files_count: 5,
        gemfiles_count: 2,
        creation_time: Time.now.iso8601
      }
    end

    before do
      create_test_project_structure
      allow(CodeqlDb::Database::Manager).to receive(:new).and_return(manager)
      allow(manager).to receive(:create).and_return(create_result)
    end

    it "creates a database using the manager" do
      expect(manager).to receive(:create).with(source_path, database_path, {})
      CodeqlDb.create_database(source_path, database_path)
    end

    it "returns the manager result" do
      result = CodeqlDb.create_database(source_path, database_path)
      expect(result).to eq(create_result)
    end

    it "passes options to the manager" do
      options = { overwrite: true, verbose: true }
      expect(manager).to receive(:create).with(source_path, database_path, options)
      CodeqlDb.create_database(source_path, database_path, options)
    end

    it "uses default database path when not provided" do
      expect(manager).to receive(:create).with(source_path, CodeqlDb.configuration.default_database_path, {})
      CodeqlDb.create_database(source_path)
    end
  end

  describe ".analyze_database" do
    let(:database_path) { File.join(temp_dir, "test_database") }
    let(:analyzer) { instance_double(CodeqlDb::Statistics::Analyzer) }
    let(:analysis_result) do
      {
        database_path: database_path,
        analysis_time: Time.now.iso8601,
        basic_stats: { total_files: 10 },
        summary: { lines_of_code: 1000 }
      }
    end

    before do
      allow(CodeqlDb::Statistics::Analyzer).to receive(:new).and_return(analyzer)
      allow(analyzer).to receive(:analyze).and_return(analysis_result)
    end

    it "analyzes a database using the analyzer" do
      expect(analyzer).to receive(:analyze).with(database_path, {})
      CodeqlDb.analyze_database(database_path)
    end

    it "returns the analyzer result" do
      result = CodeqlDb.analyze_database(database_path)
      expect(result).to eq(analysis_result)
    end

    it "passes options to the analyzer" do
      options = { detailed: true }
      expect(analyzer).to receive(:analyze).with(database_path, options)
      CodeqlDb.analyze_database(database_path, options)
    end
  end

  describe ".list_files" do
    let(:database_path) { File.join(temp_dir, "test_database") }
    let(:manager) { instance_double(CodeqlDb::Database::Manager) }
    let(:list_result) do
      {
        source_path: temp_dir,
        total_files: 7,
        ruby_files_count: 5,
        gemfiles_count: 2,
        creation_time: Time.now.iso8601
      }
    end

    before do
      allow(CodeqlDb::Database::Manager).to receive(:new).and_return(manager)
      allow(manager).to receive(:list_files).and_return(list_result)
    end

    it "lists files using the manager" do
      expect(manager).to receive(:list_files).with(database_path, {})
      CodeqlDb.list_files(database_path)
    end

    it "returns the manager result" do
      result = CodeqlDb.list_files(database_path)
      expect(result).to eq(list_result)
    end

    it "passes options to the manager" do
      options = { include_file_list: true, include_stats: true }
      expect(manager).to receive(:list_files).with(database_path, options)
      CodeqlDb.list_files(database_path, options)
    end
  end

  describe "error classes" do
    describe "CodeqlDb::Error" do
      it "is a StandardError" do
        expect(CodeqlDb::Error.new).to be_a(StandardError)
      end
    end

    describe "CodeqlDb::ConfigurationError" do
      it "is a CodeqlDb::Error" do
        expect(CodeqlDb::ConfigurationError.new).to be_a(CodeqlDb::Error)
      end
    end

    describe "CodeqlDb::DatabaseError" do
      it "is a CodeqlDb::Error" do
        expect(CodeqlDb::DatabaseError.new).to be_a(CodeqlDb::Error)
      end
    end

    describe "CodeqlDb::CLIError" do
      it "is a CodeqlDb::Error" do
        expect(CodeqlDb::CLIError.new).to be_a(CodeqlDb::Error)
      end
    end
  end

  describe "module structure" do
    it "defines the Configuration class" do
      expect(CodeqlDb::Configuration).to be_a(Class)
    end

    it "defines the Database module" do
      expect(CodeqlDb::Database).to be_a(Module)
    end

    it "defines the Database::Manager class" do
      expect(CodeqlDb::Database::Manager).to be_a(Class)
    end

    it "defines the Statistics module" do
      expect(CodeqlDb::Statistics).to be_a(Module)
    end

    it "defines the Statistics::Analyzer class" do
      expect(CodeqlDb::Statistics::Analyzer).to be_a(Class)
    end

    it "defines the CLI module" do
      expect(CodeqlDb::CLI).to be_a(Module)
    end

    it "defines the CLI::Wrapper class" do
      expect(CodeqlDb::CLI::Wrapper).to be_a(Class)
    end
  end

  describe "integration" do
    let(:source_path) { temp_dir }
    let(:database_path) { File.join(temp_dir, "integration_test_db") }

    before do
      create_test_project_structure
      mock_codeql_cli_available
    end

    context "with mocked CLI operations" do
      let(:manager) { instance_double(CodeqlDb::Database::Manager) }
      let(:analyzer) { instance_double(CodeqlDb::Statistics::Analyzer) }

      before do
        allow(CodeqlDb::Database::Manager).to receive(:new).and_return(manager)
        allow(CodeqlDb::Statistics::Analyzer).to receive(:new).and_return(analyzer)
      end

      it "can create and analyze a database" do
        # Mock database creation
        create_result = {
          database_path: database_path,
          source_path: source_path,
          ruby_files_count: 5,
          gemfiles_count: 2,
          creation_time: Time.now.iso8601
        }
        allow(manager).to receive(:create).and_return(create_result)

        # Mock database analysis
        analysis_result = {
          database_path: database_path,
          analysis_time: Time.now.iso8601,
          basic_stats: { total_files: 7, ruby_files: 5, gemfiles: 2 },
          summary: { lines_of_code: 500, total_methods: 20 }
        }
        allow(analyzer).to receive(:analyze).and_return(analysis_result)

        # Test the workflow
        create_result = CodeqlDb.create_database(source_path, database_path)
        expect(create_result[:ruby_files_count]).to eq(5)

        analysis_result = CodeqlDb.analyze_database(database_path)
        expect(analysis_result[:summary][:lines_of_code]).to eq(500)
      end

      it "can list files in a database" do
        list_result = {
          source_path: source_path,
          total_files: 7,
          ruby_files_count: 5,
          gemfiles_count: 2,
          creation_time: Time.now.iso8601
        }
        allow(manager).to receive(:list_files).and_return(list_result)

        result = CodeqlDb.list_files(database_path)
        expect(result[:total_files]).to eq(7)
      end
    end

    context "with configuration changes" do
      it "respects configuration changes" do
        CodeqlDb.configure do |config|
          config.verbose = true
          config.threads = 8
          config.ram = 8192
        end

        expect(CodeqlDb.configuration.verbose).to be true
        expect(CodeqlDb.configuration.threads).to eq(8)
        expect(CodeqlDb.configuration.ram).to eq(8192)
      end

      it "validates configuration when creating managers" do
        CodeqlDb.configure do |config|
          config.threads = -1  # Invalid
        end

        expect {
          CodeqlDb::Database::Manager.new(CodeqlDb.configuration)
        }.to raise_error(CodeqlDb::ConfigurationError)
      end
    end
  end

  describe "thread safety" do
    it "maintains separate configuration instances in different threads" do
      results = []
      
      threads = 3.times.map do |i|
        Thread.new do
          CodeqlDb.configure do |config|
            config.threads = i + 1
          end
          results << CodeqlDb.configuration.threads
        end
      end

      threads.each(&:join)
      
      # All threads should see their own configuration
      expect(results.sort).to eq([1, 2, 3])
    end
  end
end

