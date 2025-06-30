# frozen_string_literal: true

RSpec.describe RubyCodeqlDb do
  it "has a version number" do
    expect(RubyCodeqlDb::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields a configuration object" do
      expect { |b| RubyCodeqlDb.configure(&b) }.to yield_with_args(RubyCodeqlDb::Configuration)
    end

    it "allows configuration of settings" do
      RubyCodeqlDb.configure do |config|
        config.verbose = true
        config.threads = 4
        config.ram = 4096
      end

      expect(RubyCodeqlDb.configuration.verbose).to be true
      expect(RubyCodeqlDb.configuration.threads).to eq(4)
      expect(RubyCodeqlDb.configuration.ram).to eq(4096)
    end

    it "returns the configuration object" do
      config = RubyCodeqlDb.configure
      expect(config).to be_a(RubyCodeqlDb::Configuration)
    end

    it "maintains singleton configuration" do
      config1 = RubyCodeqlDb.configuration
      config2 = RubyCodeqlDb.configuration
      expect(config1).to be(config2)
    end
  end

  describe ".create_database" do
    let(:source_path) { "/tmp/test_source" }
    let(:database_path) { "/tmp/test_db" }
    let(:manager) { instance_double(RubyCodeqlDb::Database::Manager) }

    before do
      allow(RubyCodeqlDb::Database::Manager).to receive(:new).and_return(manager)
    end

    it "delegates to Database::Manager" do
      expect(manager).to receive(:create).with(source_path, database_path, {})
      RubyCodeqlDb.create_database(source_path, database_path)
    end

    it "returns the result from the manager" do
      expected_result = { success: true }
      allow(manager).to receive(:create).and_return(expected_result)
      result = RubyCodeqlDb.create_database(source_path, database_path)
      expect(result).to eq(expected_result)
    end

    it "passes options to the manager" do
      options = { overwrite: true, verbose: true }
      expect(manager).to receive(:create).with(source_path, database_path, options)
      RubyCodeqlDb.create_database(source_path, database_path, options)
    end

    it "uses default database path when not specified" do
      expect(manager).to receive(:create).with(source_path, RubyCodeqlDb.configuration.default_database_path, {})
      RubyCodeqlDb.create_database(source_path)
    end
  end

  describe ".analyze_database" do
    let(:database_path) { "/tmp/test_db" }
    let(:analyzer) { instance_double(RubyCodeqlDb::Statistics::Analyzer) }

    before do
      allow(RubyCodeqlDb::Statistics::Analyzer).to receive(:new).and_return(analyzer)
    end

    it "delegates to Statistics::Analyzer" do
      expect(analyzer).to receive(:analyze).with(database_path, {})
      RubyCodeqlDb.analyze_database(database_path)
    end

    it "returns the result from the analyzer" do
      expected_result = { analysis: "complete" }
      allow(analyzer).to receive(:analyze).and_return(expected_result)
      result = RubyCodeqlDb.analyze_database(database_path)
      expect(result).to eq(expected_result)
    end

    it "passes options to the analyzer" do
      options = { detailed: true }
      expect(analyzer).to receive(:analyze).with(database_path, options)
      RubyCodeqlDb.analyze_database(database_path, options)
    end
  end

  describe ".list_files" do
    let(:database_path) { "/tmp/test_db" }
    let(:manager) { instance_double(RubyCodeqlDb::Database::Manager) }

    before do
      allow(RubyCodeqlDb::Database::Manager).to receive(:new).and_return(manager)
    end

    it "delegates to Database::Manager" do
      expect(manager).to receive(:list_files).with(database_path, {})
      RubyCodeqlDb.list_files(database_path)
    end

    it "returns the result from the manager" do
      expected_result = { files: [] }
      allow(manager).to receive(:list_files).and_return(expected_result)
      result = RubyCodeqlDb.list_files(database_path)
      expect(result).to eq(expected_result)
    end

    it "passes options to the manager" do
      options = { include_files: true }
      expect(manager).to receive(:list_files).with(database_path, options)
      RubyCodeqlDb.list_files(database_path, options)
    end
  end

  describe "Error classes" do
    describe "RubyCodeqlDb::Error" do
      it "is a StandardError" do
        expect(RubyCodeqlDb::Error.new).to be_a(StandardError)
      end
    end

    describe "RubyCodeqlDb::ConfigurationError" do
      it "is a RubyCodeqlDb::Error" do
        expect(RubyCodeqlDb::ConfigurationError.new).to be_a(RubyCodeqlDb::Error)
      end
    end

    describe "RubyCodeqlDb::DatabaseError" do
      it "is a RubyCodeqlDb::Error" do
        expect(RubyCodeqlDb::DatabaseError.new).to be_a(RubyCodeqlDb::Error)
      end
    end

    describe "RubyCodeqlDb::CLIError" do
      it "is a RubyCodeqlDb::Error" do
        expect(RubyCodeqlDb::CLIError.new).to be_a(RubyCodeqlDb::Error)
      end
    end
  end

  describe "Module structure" do
    it "has Configuration class" do
      expect(RubyCodeqlDb::Configuration).to be_a(Class)
    end

    it "has Database module" do
      expect(RubyCodeqlDb::Database).to be_a(Module)
    end

    it "has Database::Manager class" do
      expect(RubyCodeqlDb::Database::Manager).to be_a(Class)
    end

    it "has Statistics module" do
      expect(RubyCodeqlDb::Statistics).to be_a(Module)
    end

    it "has Statistics::Analyzer class" do
      expect(RubyCodeqlDb::Statistics::Analyzer).to be_a(Class)
    end

    it "has CLI module" do
      expect(RubyCodeqlDb::CLI).to be_a(Module)
    end

    it "has CLI::Wrapper class" do
      expect(RubyCodeqlDb::CLI::Wrapper).to be_a(Class)
    end
  end

  describe "Integration" do
    let(:manager) { instance_double(RubyCodeqlDb::Database::Manager) }
    let(:analyzer) { instance_double(RubyCodeqlDb::Statistics::Analyzer) }

    before do
      allow(RubyCodeqlDb::Database::Manager).to receive(:new).and_return(manager)
      allow(RubyCodeqlDb::Statistics::Analyzer).to receive(:new).and_return(analyzer)
    end

    it "can create and analyze a database" do
      create_result = { success: true }
      analyze_result = { analysis: "complete" }

      allow(manager).to receive(:create).and_return(create_result)
      allow(analyzer).to receive(:analyze).and_return(analyze_result)

      expect(RubyCodeqlDb.create_database("/tmp/source", "/tmp/db")).to eq(create_result)
      expect(RubyCodeqlDb.analyze_database("/tmp/db")).to eq(analyze_result)
    end
  end
end

