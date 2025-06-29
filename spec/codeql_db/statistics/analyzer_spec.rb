# frozen_string_literal: true

RSpec.describe CodeqlDb::Statistics::Analyzer do
  let(:config) { CodeqlDb::Configuration.new }
  let(:analyzer) { described_class.new(config) }
  let(:database_path) { File.join(temp_dir, "test_database") }

  before do
    create_test_project_structure
    FileUtils.mkdir_p(database_path)
  end

  describe "#initialize" do
    it "accepts a configuration object" do
      expect(analyzer.config).to eq(config)
    end
  end

  describe "#analyze" do
    let(:manager) { instance_double(CodeqlDb::Database::Manager) }
    let(:database_info) do
      {
        metadata: {
          ruby_files: Dir.glob(File.join(temp_dir, "**/*.rb")),
          gemfiles: Dir.glob(File.join(temp_dir, "**/Gemfile*")) + Dir.glob(File.join(temp_dir, "**/*.gemspec")),
          creation_time: Time.now.iso8601
        },
        size: { human_readable: "1.2 MB", bytes: 1258291 }
      }
    end

    before do
      allow(CodeqlDb::Database::Manager).to receive(:new).and_return(manager)
      allow(manager).to receive(:info).and_return(database_info)
    end

    it "returns comprehensive analysis" do
      result = analyzer.analyze(database_path)

      expect(result).to include(
        :database_path,
        :analysis_time,
        :basic_stats,
        :file_analysis,
        :code_metrics,
        :gemfile_analysis,
        :complexity_analysis,
        :summary
      )
    end

    it "includes basic statistics" do
      result = analyzer.analyze(database_path)
      basic_stats = result[:basic_stats]

      expect(basic_stats).to include(
        :total_files,
        :ruby_files,
        :gemfiles,
        :database_size,
        :creation_time
      )
    end

    it "includes file analysis" do
      result = analyzer.analyze(database_path)
      file_analysis = result[:file_analysis]

      expect(file_analysis).to include(
        :file_types,
        :largest_files,
        :directory_distribution,
        :file_size_distribution,
        :naming_patterns
      )
    end

    it "includes code metrics" do
      result = analyzer.analyze(database_path)
      code_metrics = result[:code_metrics]

      expect(code_metrics).to include(
        :lines_of_code,
        :average_file_size,
        :file_count_by_size,
        :method_density,
        :class_distribution
      )
    end

    it "includes complexity analysis" do
      result = analyzer.analyze(database_path)
      complexity = result[:complexity_analysis]

      expect(complexity).to include(
        :cyclomatic_complexity,
        :nesting_depth,
        :method_length_distribution,
        :class_size_distribution
      )
    end

    it "includes comprehensive summary" do
      result = analyzer.analyze(database_path)
      summary = result[:summary]

      expect(summary).to include(
        :total_files,
        :primary_language,
        :lines_of_code,
        :total_methods,
        :total_classes,
        :complexity_score
      )
    end

    context "with non-existent database" do
      it "raises error" do
        expect {
          analyzer.analyze("/non/existent/database")
        }.to raise_error(CodeqlDb::DatabaseError, /Database not found/)
      end
    end
  end

  describe "#calculate_lines_of_code" do
    let(:test_files) do
      [
        create_test_ruby_file("test1.rb", <<~RUBY),
          # This is a comment
          class TestClass
            def method1
              puts "Hello"
            end
          
            # Another comment
            def method2
              # Inline comment
              return true
            end
          end
        RUBY
        create_test_ruby_file("test2.rb", <<~RUBY)
          # File header comment
          
          module TestModule
            # Module comment
            def self.helper
              value = 42
              value * 2
            end
          end
          
          # End comment
        RUBY
      ]
    end

    it "counts lines correctly" do
      result = analyzer.calculate_lines_of_code(test_files)

      expect(result).to include(
        :total_lines,
        :code_lines,
        :comment_lines,
        :blank_lines,
        :comment_ratio
      )

      expect(result[:total_lines]).to be > 0
      expect(result[:code_lines]).to be > 0
      expect(result[:comment_lines]).to be > 0
      expect(result[:blank_lines]).to be > 0
    end

    it "calculates comment ratio correctly" do
      result = analyzer.calculate_lines_of_code(test_files)
      expected_ratio = (result[:comment_lines].to_f / result[:total_lines] * 100).round(2)
      expect(result[:comment_ratio]).to eq(expected_ratio)
    end

    it "handles empty file list" do
      result = analyzer.calculate_lines_of_code([])
      expect(result[:total_lines]).to eq(0)
      expect(result[:comment_ratio]).to eq(0)
    end

    it "handles non-existent files gracefully" do
      result = analyzer.calculate_lines_of_code(["/non/existent/file.rb"])
      expect(result[:total_lines]).to eq(0)
    end
  end

  describe "private methods" do
    let(:ruby_files) { Dir.glob(File.join(temp_dir, "**/*.rb")) }
    let(:gemfiles) { Dir.glob(File.join(temp_dir, "**/Gemfile*")) + Dir.glob(File.join(temp_dir, "**/*.gemspec")) }
    let(:all_files) { ruby_files + gemfiles }

    describe "#count_file_types" do
      it "counts file types correctly" do
        result = analyzer.send(:count_file_types, all_files)
        expect(result[".rb"]).to be > 0
        expect(result[".gemspec"]).to be > 0
        expect(result["no_extension"]).to be > 0  # Gemfile has no extension
      end
    end

    describe "#find_largest_files" do
      it "returns largest files" do
        result = analyzer.send(:find_largest_files, all_files, 3)
        expect(result).to be_an(Array)
        expect(result.length).to be <= 3
        expect(result.first).to include(:path, :size, :relative_path, :size_kb)
      end

      it "sorts by size descending" do
        result = analyzer.send(:find_largest_files, all_files, 5)
        sizes = result.map { |f| f[:size] }
        expect(sizes).to eq(sizes.sort.reverse)
      end
    end

    describe "#analyze_directory_distribution" do
      it "counts files per directory" do
        result = analyzer.send(:analyze_directory_distribution, all_files)
        expect(result).to be_a(Hash)
        expect(result.values.sum).to eq(all_files.length)
      end

      it "sorts by file count descending" do
        result = analyzer.send(:analyze_directory_distribution, all_files)
        counts = result.values
        expect(counts).to eq(counts.sort.reverse)
      end
    end

    describe "#analyze_file_size_distribution" do
      it "categorizes files by size" do
        result = analyzer.send(:analyze_file_size_distribution, all_files)
        expect(result).to include(:tiny, :small, :medium, :large, :huge)
        expect(result.values.sum).to eq(all_files.length)
      end
    end

    describe "#analyze_naming_patterns" do
      it "analyzes naming patterns" do
        result = analyzer.send(:analyze_naming_patterns, ruby_files)
        expect(result).to include(
          :snake_case, :camel_case, :mixed_case,
          :with_numbers, :test_files, :spec_files
        )
      end

      it "counts snake_case files correctly" do
        result = analyzer.send(:analyze_naming_patterns, ruby_files)
        expect(result[:snake_case]).to be > 0
      end

      it "counts spec files correctly" do
        result = analyzer.send(:analyze_naming_patterns, ruby_files)
        expect(result[:spec_files]).to be > 0  # We have spec files in test structure
      end
    end

    describe "#calculate_average_file_size" do
      it "calculates average file size" do
        result = analyzer.send(:calculate_average_file_size, ruby_files)
        expect(result).to include(:bytes, :kb, :human_readable)
        expect(result[:bytes]).to be > 0
      end

      it "handles empty file list" do
        result = analyzer.send(:calculate_average_file_size, [])
        expect(result).to eq(0)
      end
    end

    describe "#estimate_method_density" do
      it "estimates method density" do
        result = analyzer.send(:estimate_method_density, ruby_files)
        expect(result).to include(
          :total_methods, :total_lines,
          :methods_per_line, :average_method_length
        )
        expect(result[:total_methods]).to be > 0
      end
    end

    describe "#analyze_class_distribution" do
      it "analyzes class and module distribution" do
        result = analyzer.send(:analyze_class_distribution, ruby_files)
        expect(result).to include(
          :total_classes, :total_modules,
          :classes_per_file, :modules_per_file
        )
        expect(result[:total_classes]).to be > 0
        expect(result[:total_modules]).to be > 0
      end
    end

    describe "#estimate_cyclomatic_complexity" do
      it "estimates cyclomatic complexity" do
        result = analyzer.send(:estimate_cyclomatic_complexity, ruby_files)
        expect(result).to include(
          :total_complexity, :average_complexity, :files_analyzed
        )
        expect(result[:total_complexity]).to be > 0
      end
    end

    describe "#analyze_nesting_depth" do
      it "analyzes nesting depth" do
        result = analyzer.send(:analyze_nesting_depth, ruby_files)
        expect(result).to include(
          :max_nesting_depth, :average_nesting_depth, :files_analyzed
        )
        expect(result[:max_nesting_depth]).to be > 0
      end
    end

    describe "#analyze_method_lengths" do
      it "analyzes method lengths" do
        result = analyzer.send(:analyze_method_lengths, ruby_files)
        if result[:methods_found] > 0
          expect(result).to include(
            :methods_found, :average_length,
            :min_length, :max_length, :median_length
          )
        else
          expect(result[:methods_found]).to eq(0)
        end
      end
    end

    describe "#analyze_class_sizes" do
      it "analyzes class sizes" do
        result = analyzer.send(:analyze_class_sizes, ruby_files)
        if result[:classes_found] > 0
          expect(result).to include(
            :classes_found, :average_size,
            :min_size, :max_size, :median_size
          )
        else
          expect(result[:classes_found]).to eq(0)
        end
      end
    end

    describe "#analyze_gemfiles" do
      let(:database_info) do
        { metadata: { gemfiles: gemfiles } }
      end

      it "analyzes gemfiles" do
        result = analyzer.send(:analyze_gemfiles, database_info)
        expect(result).to include(
          :gemfile_count, :gemfile_types,
          :dependencies, :gemspec_analysis
        )
        expect(result[:gemfile_count]).to be > 0
      end

      it "categorizes gemfile types" do
        result = analyzer.send(:analyze_gemfiles, database_info)
        types = result[:gemfile_types]
        expect(types).to include(:gemfile, :gemspec)
      end
    end

    describe "#analyze_gemspec_file" do
      let(:gemspec_path) { create_test_gemspec("test_gem") }

      it "analyzes gemspec file" do
        result = analyzer.send(:analyze_gemspec_file, gemspec_path)
        expect(result).to include(
          :has_dependencies, :has_dev_dependencies,
          :has_version, :has_description, :line_count
        )
      end
    end

    describe "#analyze_gemfile_dependencies" do
      let(:gemfile_path) { create_test_gemfile }

      it "analyzes Gemfile dependencies" do
        result = analyzer.send(:analyze_gemfile_dependencies, gemfile_path)
        expect(result).to include(
          :total_gems, :has_source, :has_groups, :line_count
        )
        expect(result[:total_gems]).to be > 0
      end
    end

    describe "#format_bytes" do
      it "formats bytes correctly" do
        expect(analyzer.send(:format_bytes, 1024)).to eq("1.0 KB")
        expect(analyzer.send(:format_bytes, 1048576)).to eq("1.0 MB")
        expect(analyzer.send(:format_bytes, 1073741824)).to eq("1.0 GB")
      end
    end
  end
end

