# frozen_string_literal: true

RSpec.describe CodeqlDb::Database::Manager do
  let(:config) { CodeqlDb::Configuration.new }
  let(:manager) { described_class.new(config) }
  let(:database_path) { File.join(temp_dir, "test_database") }
  let(:source_path) { temp_dir }

  before do
    mock_codeql_cli_available
    create_test_project_structure
  end

  describe "#initialize" do
    it "accepts a configuration object" do
      expect(manager.config).to eq(config)
    end

    it "validates configuration on initialization" do
      expect(config).to receive(:validate!)
      described_class.new(config)
    end
  end

  describe "#create" do
    let(:cli_wrapper) { instance_double(CodeqlDb::CLI::Wrapper) }

    before do
      allow(CodeqlDb::CLI::Wrapper).to receive(:new).and_return(cli_wrapper)
      allow(cli_wrapper).to receive(:create_database).and_return(true)
      allow(manager).to receive(:save_metadata)
    end

    context "with valid parameters" do
      it "creates a database successfully" do
        result = manager.create(source_path, database_path)

        expect(result).to include(
          :database_path,
          :source_path,
          :ruby_files_count,
          :gemfiles_count,
          :creation_time
        )
        expect(result[:database_path]).to eq(database_path)
        expect(result[:source_path]).to eq(source_path)
      end

      it "scans Ruby files correctly" do
        result = manager.create(source_path, database_path)
        expect(result[:ruby_files_count]).to be > 0
      end

      it "scans Gemfiles correctly" do
        result = manager.create(source_path, database_path)
        expect(result[:gemfiles_count]).to be > 0
      end

      it "calls CLI wrapper with correct parameters" do
        expect(cli_wrapper).to receive(:create_database).with(
          source_path,
          database_path,
          hash_including(:language, :threads, :ram)
        )

        manager.create(source_path, database_path)
      end

      it "saves metadata after creation" do
        expect(manager).to receive(:save_metadata).with(
          database_path,
          hash_including(:source_path, :ruby_files, :gemfiles)
        )

        manager.create(source_path, database_path)
      end
    end

    context "with overwrite option" do
      before do
        FileUtils.mkdir_p(database_path)
      end

      it "removes existing database when overwrite is true" do
        expect(FileUtils).to receive(:rm_rf).with(database_path)
        manager.create(source_path, database_path, overwrite: true)
      end

      it "raises error when database exists and overwrite is false" do
        expect {
          manager.create(source_path, database_path, overwrite: false)
        }.to raise_error(CodeqlDb::DatabaseError, /already exists/)
      end
    end

    context "with invalid source path" do
      it "raises error for non-existent source" do
        expect {
          manager.create("/non/existent/path", database_path)
        }.to raise_error(CodeqlDb::DatabaseError, /Source path does not exist/)
      end
    end

    context "when CLI command fails" do
      before do
        allow(cli_wrapper).to receive(:create_database).and_raise(CodeqlDb::CLIError, "CLI failed")
      end

      it "raises a database error" do
        expect {
          manager.create(source_path, database_path)
        }.to raise_error(CodeqlDb::DatabaseError, /Failed to create database/)
      end
    end
  end

  describe "#list_files" do
    let(:metadata) do
      {
        source_path: source_path,
        ruby_files: ["lib/test.rb", "app/model.rb"],
        gemfiles: ["Gemfile", "test.gemspec"],
        creation_time: Time.now.iso8601
      }
    end

    before do
      FileUtils.mkdir_p(database_path)
      allow(manager).to receive(:load_metadata).and_return(metadata)
    end

    it "returns file information" do
      result = manager.list_files(database_path)

      expect(result).to include(
        :source_path,
        :total_files,
        :ruby_files_count,
        :gemfiles_count,
        :creation_time
      )
    end

    it "calculates total files correctly" do
      result = manager.list_files(database_path)
      expect(result[:total_files]).to eq(4)
    end

    context "with include_file_list option" do
      it "includes file lists when requested" do
        result = manager.list_files(database_path, include_file_list: true)
        expect(result[:files]).to include("lib/test.rb", "app/model.rb", "Gemfile", "test.gemspec")
      end

      it "excludes file lists by default" do
        result = manager.list_files(database_path)
        expect(result).not_to have_key(:files)
      end
    end

    context "with include_stats option" do
      it "includes statistics when requested" do
        result = manager.list_files(database_path, include_stats: true)
        expect(result).to have_key(:statistics)
      end
    end

    context "with non-existent database" do
      it "raises error" do
        expect {
          manager.list_files("/non/existent/database")
        }.to raise_error(CodeqlDb::DatabaseError, /Database not found/)
      end
    end
  end

  describe "#delete" do
    before do
      FileUtils.mkdir_p(database_path)
    end

    it "deletes the database directory" do
      result = manager.delete(database_path)
      
      expect(File.exist?(database_path)).to be false
      expect(result[:path]).to eq(database_path)
    end

    context "with non-existent database" do
      it "raises error" do
        expect {
          manager.delete("/non/existent/database")
        }.to raise_error(CodeqlDb::DatabaseError, /Database not found/)
      end
    end
  end

  describe "#exists?" do
    context "when database exists" do
      before do
        FileUtils.mkdir_p(database_path)
      end

      it "returns true" do
        expect(manager.exists?(database_path)).to be true
      end
    end

    context "when database does not exist" do
      it "returns false" do
        expect(manager.exists?("/non/existent/database")).to be false
      end
    end
  end

  describe "#info" do
    let(:metadata) do
      {
        source_path: source_path,
        ruby_files: ["lib/test.rb"],
        gemfiles: ["Gemfile"],
        creation_time: Time.now.iso8601,
        config: {
          language: "ruby",
          threads: 2,
          ram: 2048,
          build_mode: "none"
        }
      }
    end

    before do
      FileUtils.mkdir_p(database_path)
      File.write(File.join(database_path, "test_file"), "test content")
      allow(manager).to receive(:load_metadata).and_return(metadata)
    end

    it "returns database information" do
      result = manager.info(database_path)

      expect(result).to include(
        :database_path,
        :size,
        :metadata
      )
    end

    it "calculates database size" do
      result = manager.info(database_path)
      expect(result[:size]).to include(:bytes, :human_readable)
      expect(result[:size][:bytes]).to be > 0
    end

    it "includes metadata" do
      result = manager.info(database_path)
      expect(result[:metadata]).to eq(metadata)
    end

    context "with non-existent database" do
      it "raises error" do
        expect {
          manager.info("/non/existent/database")
        }.to raise_error(CodeqlDb::DatabaseError, /Database not found/)
      end
    end
  end

  describe "private methods" do
    describe "#scan_ruby_files" do
      it "finds Ruby files" do
        ruby_files = manager.send(:scan_ruby_files, source_path)
        expect(ruby_files).to include(
          a_string_ending_with("lib/test_gem.rb"),
          a_string_ending_with("app/models/user.rb")
        )
      end

      it "excludes files in excluded patterns" do
        config.exclude_patterns << "app"
        ruby_files = manager.send(:scan_ruby_files, source_path)
        expect(ruby_files).not_to include(a_string_including("app/"))
      end
    end

    describe "#scan_gemfiles" do
      it "finds Gemfiles and gemspecs" do
        gemfiles = manager.send(:scan_gemfiles, source_path)
        expect(gemfiles).to include(
          a_string_ending_with("Gemfile"),
          a_string_ending_with(".gemspec")
        )
      end

      it "excludes gemfiles when include_gemfiles is false" do
        config.include_gemfiles = false
        gemfiles = manager.send(:scan_gemfiles, source_path)
        expect(gemfiles).to be_empty
      end
    end

    describe "#save_metadata and #load_metadata" do
      let(:metadata) do
        {
          source_path: source_path,
          ruby_files: ["test.rb"],
          gemfiles: ["Gemfile"],
          creation_time: Time.now.iso8601
        }
      end

      before do
        FileUtils.mkdir_p(database_path)
      end

      it "saves and loads metadata correctly" do
        manager.send(:save_metadata, database_path, metadata)
        loaded_metadata = manager.send(:load_metadata, database_path)
        
        expect(loaded_metadata[:source_path]).to eq(metadata[:source_path])
        expect(loaded_metadata[:ruby_files]).to eq(metadata[:ruby_files])
        expect(loaded_metadata[:gemfiles]).to eq(metadata[:gemfiles])
      end

      it "returns empty hash when metadata file doesn't exist" do
        loaded_metadata = manager.send(:load_metadata, database_path)
        expect(loaded_metadata).to eq({})
      end
    end

    describe "#calculate_directory_size" do
      before do
        FileUtils.mkdir_p(database_path)
        File.write(File.join(database_path, "file1"), "a" * 100)
        File.write(File.join(database_path, "file2"), "b" * 200)
      end

      it "calculates total directory size" do
        size = manager.send(:calculate_directory_size, database_path)
        expect(size).to eq(300)
      end
    end

    describe "#format_bytes" do
      it "formats bytes correctly" do
        expect(manager.send(:format_bytes, 1024)).to eq("1.0 KB")
        expect(manager.send(:format_bytes, 1048576)).to eq("1.0 MB")
        expect(manager.send(:format_bytes, 1073741824)).to eq("1.0 GB")
      end

      it "handles small sizes" do
        expect(manager.send(:format_bytes, 500)).to eq("500.0 B")
      end
    end
  end
end

