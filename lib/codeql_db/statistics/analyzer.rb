# frozen_string_literal: true

module CodeqlDb
  module Statistics
    # Analyzer for generating comprehensive statistics from CodeQL databases
    class Analyzer
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def analyze(database_path, options = {})
        database_path = File.expand_path(database_path)
        
        unless File.exist?(database_path)
          raise DatabaseError, "Database not found: #{database_path}"
        end

        # Load database metadata
        manager = Database::Manager.new(config)
        database_info = manager.info(database_path)
        
        # Comprehensive analysis
        analysis = {
          database_path: database_path,
          analysis_time: Time.now.iso8601,
          basic_stats: calculate_basic_stats(database_info),
          file_analysis: analyze_files(database_info),
          code_metrics: calculate_code_metrics(database_info),
          gemfile_analysis: analyze_gemfiles(database_info),
          complexity_analysis: analyze_complexity(database_info),
          summary: {}
        }

        # Generate comprehensive summary
        analysis[:summary] = generate_comprehensive_summary(analysis)
        
        analysis
      end

      def calculate_lines_of_code(file_paths)
        total_lines = 0
        code_lines = 0
        comment_lines = 0
        blank_lines = 0
        
        file_paths.each do |file_path|
          next unless File.exist?(file_path) && File.readable?(file_path)
          
          begin
            lines = File.readlines(file_path)
            total_lines += lines.count
            
            lines.each do |line|
              stripped = line.strip
              if stripped.empty?
                blank_lines += 1
              elsif stripped.start_with?('#')
                comment_lines += 1
              else
                code_lines += 1
              end
            end
          rescue => e
            puts "Warning: Could not read #{file_path}: #{e.message}" if config.verbose
          end
        end
        
        {
          total_lines: total_lines,
          code_lines: code_lines,
          comment_lines: comment_lines,
          blank_lines: blank_lines,
          comment_ratio: total_lines > 0 ? (comment_lines.to_f / total_lines * 100).round(2) : 0
        }
      end

      private

      def calculate_basic_stats(database_info)
        metadata = database_info[:metadata]
        
        {
          total_files: (metadata[:ruby_files]&.count || 0) + (metadata[:gemfiles]&.count || 0),
          ruby_files: metadata[:ruby_files]&.count || 0,
          gemfiles: metadata[:gemfiles]&.count || 0,
          database_size: database_info[:size],
          creation_time: metadata[:creation_time]
        }
      end

      def analyze_files(database_info)
        metadata = database_info[:metadata]
        ruby_files = metadata[:ruby_files] || []
        gemfiles = metadata[:gemfiles] || []
        all_files = ruby_files + gemfiles

        {
          file_types: count_file_types(all_files),
          largest_files: find_largest_files(all_files),
          directory_distribution: analyze_directory_distribution(all_files),
          file_size_distribution: analyze_file_size_distribution(all_files),
          naming_patterns: analyze_naming_patterns(ruby_files)
        }
      end

      def calculate_code_metrics(database_info)
        metadata = database_info[:metadata]
        ruby_files = metadata[:ruby_files] || []
        
        # Calculate lines of code for Ruby files
        loc_stats = calculate_lines_of_code(ruby_files)
        
        # Calculate additional metrics
        {
          lines_of_code: loc_stats,
          average_file_size: calculate_average_file_size(ruby_files),
          file_count_by_size: categorize_files_by_size(ruby_files),
          method_density: estimate_method_density(ruby_files),
          class_distribution: analyze_class_distribution(ruby_files)
        }
      end

      def analyze_gemfiles(database_info)
        metadata = database_info[:metadata]
        gemfiles = metadata[:gemfiles] || []
        
        analysis = {
          gemfile_count: gemfiles.count,
          gemfile_types: {},
          dependencies: {},
          gemspec_analysis: {}
        }
        
        gemfiles.each do |gemfile|
          basename = File.basename(gemfile)
          
          # Categorize gemfile types
          if basename.end_with?('.gemspec')
            analysis[:gemfile_types][:gemspec] = (analysis[:gemfile_types][:gemspec] || 0) + 1
            analysis[:gemspec_analysis].merge!(analyze_gemspec_file(gemfile))
          elsif basename == 'Gemfile'
            analysis[:gemfile_types][:gemfile] = (analysis[:gemfile_types][:gemfile] || 0) + 1
            analysis[:dependencies].merge!(analyze_gemfile_dependencies(gemfile))
          elsif basename.start_with?('Gemfile.')
            analysis[:gemfile_types][:gemfile_variant] = (analysis[:gemfile_types][:gemfile_variant] || 0) + 1
          end
        end
        
        analysis
      end

      def analyze_complexity(database_info)
        metadata = database_info[:metadata]
        ruby_files = metadata[:ruby_files] || []
        
        {
          cyclomatic_complexity: estimate_cyclomatic_complexity(ruby_files),
          nesting_depth: analyze_nesting_depth(ruby_files),
          method_length_distribution: analyze_method_lengths(ruby_files),
          class_size_distribution: analyze_class_sizes(ruby_files)
        }
      end

      def count_file_types(files)
        types = {}
        
        files.each do |file|
          ext = File.extname(file).downcase
          ext = "no_extension" if ext.empty?
          types[ext] = (types[ext] || 0) + 1
        end

        types
      end

      def find_largest_files(files, limit = 10)
        file_sizes = files.map do |file|
          {
            path: file,
            size: File.exist?(file) ? File.size(file) : 0,
            relative_path: file,
            size_kb: File.exist?(file) ? (File.size(file) / 1024.0).round(2) : 0
          }
        end

        file_sizes.sort_by { |f| -f[:size] }.first(limit)
      end

      def analyze_directory_distribution(files)
        dirs = {}
        
        files.each do |file|
          dir = File.dirname(file)
          dirs[dir] = (dirs[dir] || 0) + 1
        end

        dirs.sort_by { |_, count| -count }.to_h
      end

      def analyze_file_size_distribution(files)
        distribution = {
          tiny: 0,      # < 1KB
          small: 0,     # 1KB - 10KB
          medium: 0,    # 10KB - 100KB
          large: 0,     # 100KB - 1MB
          huge: 0       # > 1MB
        }
        
        files.each do |file|
          next unless File.exist?(file)
          
          size = File.size(file)
          case size
          when 0...1024
            distribution[:tiny] += 1
          when 1024...10240
            distribution[:small] += 1
          when 10240...102400
            distribution[:medium] += 1
          when 102400...1048576
            distribution[:large] += 1
          else
            distribution[:huge] += 1
          end
        end
        
        distribution
      end

      def analyze_naming_patterns(ruby_files)
        patterns = {
          snake_case: 0,
          camel_case: 0,
          mixed_case: 0,
          with_numbers: 0,
          test_files: 0,
          spec_files: 0
        }
        
        ruby_files.each do |file|
          basename = File.basename(file, '.*')
          
          patterns[:snake_case] += 1 if basename.match?(/^[a-z][a-z0-9_]*$/)
          patterns[:camel_case] += 1 if basename.match?(/^[A-Z][a-zA-Z0-9]*$/)
          patterns[:mixed_case] += 1 if basename.match?(/[A-Z]/) && basename.match?(/[a-z]/)
          patterns[:with_numbers] += 1 if basename.match?(/\d/)
          patterns[:test_files] += 1 if basename.include?('test')
          patterns[:spec_files] += 1 if basename.include?('spec')
        end
        
        patterns
      end

      def calculate_average_file_size(files)
        return 0 if files.empty?
        
        total_size = files.sum { |file| File.exist?(file) ? File.size(file) : 0 }
        average_bytes = total_size.to_f / files.count
        
        {
          bytes: average_bytes.round(2),
          kb: (average_bytes / 1024.0).round(2),
          human_readable: format_bytes(average_bytes)
        }
      end

      def categorize_files_by_size(files)
        categories = {
          tiny: [],      # < 1KB
          small: [],     # 1KB - 10KB
          medium: [],    # 10KB - 100KB
          large: [],     # 100KB+
        }
        
        files.each do |file|
          next unless File.exist?(file)
          
          size = File.size(file)
          case size
          when 0...1024
            categories[:tiny] << file
          when 1024...10240
            categories[:small] << file
          when 10240...102400
            categories[:medium] << file
          else
            categories[:large] << file
          end
        end
        
        # Return counts instead of file lists for summary
        categories.transform_values(&:count)
      end

      def estimate_method_density(ruby_files)
        total_methods = 0
        total_lines = 0
        
        ruby_files.each do |file|
          next unless File.exist?(file) && File.readable?(file)
          
          begin
            content = File.read(file)
            lines = content.lines.count
            methods = content.scan(/^\s*def\s+/).count
            
            total_methods += methods
            total_lines += lines
          rescue => e
            puts "Warning: Could not analyze #{file}: #{e.message}" if config.verbose
          end
        end
        
        {
          total_methods: total_methods,
          total_lines: total_lines,
          methods_per_line: total_lines > 0 ? (total_methods.to_f / total_lines * 100).round(4) : 0,
          average_method_length: total_methods > 0 ? (total_lines.to_f / total_methods).round(2) : 0
        }
      end

      def analyze_class_distribution(ruby_files)
        classes = 0
        modules = 0
        
        ruby_files.each do |file|
          next unless File.exist?(file) && File.readable?(file)
          
          begin
            content = File.read(file)
            classes += content.scan(/^\s*class\s+/).count
            modules += content.scan(/^\s*module\s+/).count
          rescue => e
            puts "Warning: Could not analyze #{file}: #{e.message}" if config.verbose
          end
        end
        
        {
          total_classes: classes,
          total_modules: modules,
          classes_per_file: ruby_files.count > 0 ? (classes.to_f / ruby_files.count).round(2) : 0,
          modules_per_file: ruby_files.count > 0 ? (modules.to_f / ruby_files.count).round(2) : 0
        }
      end

      def analyze_gemspec_file(gemspec_path)
        return {} unless File.exist?(gemspec_path) && File.readable?(gemspec_path)
        
        begin
          content = File.read(gemspec_path)
          
          {
            has_dependencies: content.include?('add_dependency') || content.include?('add_runtime_dependency'),
            has_dev_dependencies: content.include?('add_development_dependency'),
            has_version: content.include?('version'),
            has_description: content.include?('description'),
            has_homepage: content.include?('homepage'),
            line_count: content.lines.count
          }
        rescue => e
          puts "Warning: Could not analyze gemspec #{gemspec_path}: #{e.message}" if config.verbose
          {}
        end
      end

      def analyze_gemfile_dependencies(gemfile_path)
        return {} unless File.exist?(gemfile_path) && File.readable?(gemfile_path)
        
        begin
          content = File.read(gemfile_path)
          
          # Simple regex-based analysis
          gem_lines = content.lines.select { |line| line.strip.start_with?('gem ') }
          
          {
            total_gems: gem_lines.count,
            has_source: content.include?('source '),
            has_groups: content.include?('group '),
            has_git_dependencies: content.include?('git:'),
            has_path_dependencies: content.include?('path:'),
            line_count: content.lines.count
          }
        rescue => e
          puts "Warning: Could not analyze Gemfile #{gemfile_path}: #{e.message}" if config.verbose
          {}
        end
      end

      def estimate_cyclomatic_complexity(ruby_files)
        total_complexity = 0
        file_count = 0
        
        ruby_files.each do |file|
          next unless File.exist?(file) && File.readable?(file)
          
          begin
            content = File.read(file)
            
            # Simple complexity estimation based on control structures
            complexity = 1 # Base complexity
            complexity += content.scan(/\b(if|unless|while|until|for|case)\b/).count
            complexity += content.scan(/\b(rescue|ensure)\b/).count
            complexity += content.scan(/&&|\|\|/).count
            
            total_complexity += complexity
            file_count += 1
          rescue => e
            puts "Warning: Could not analyze complexity for #{file}: #{e.message}" if config.verbose
          end
        end
        
        {
          total_complexity: total_complexity,
          average_complexity: file_count > 0 ? (total_complexity.to_f / file_count).round(2) : 0,
          files_analyzed: file_count
        }
      end

      def analyze_nesting_depth(ruby_files)
        max_depth = 0
        total_depth = 0
        file_count = 0
        
        ruby_files.each do |file|
          next unless File.exist?(file) && File.readable?(file)
          
          begin
            content = File.read(file)
            current_depth = 0
            file_max_depth = 0
            
            content.lines.each do |line|
              stripped = line.strip
              
              # Increase depth for opening constructs
              if stripped.match?(/\b(class|module|def|if|unless|while|until|for|case|begin)\b/)
                current_depth += 1
                file_max_depth = [file_max_depth, current_depth].max
              end
              
              # Decrease depth for closing constructs
              if stripped == 'end'
                current_depth = [current_depth - 1, 0].max
              end
            end
            
            max_depth = [max_depth, file_max_depth].max
            total_depth += file_max_depth
            file_count += 1
          rescue => e
            puts "Warning: Could not analyze nesting for #{file}: #{e.message}" if config.verbose
          end
        end
        
        {
          max_nesting_depth: max_depth,
          average_nesting_depth: file_count > 0 ? (total_depth.to_f / file_count).round(2) : 0,
          files_analyzed: file_count
        }
      end

      def analyze_method_lengths(ruby_files)
        method_lengths = []
        
        ruby_files.each do |file|
          next unless File.exist?(file) && File.readable?(file)
          
          begin
            content = File.read(file)
            lines = content.lines
            
            in_method = false
            method_start = 0
            
            lines.each_with_index do |line, index|
              stripped = line.strip
              
              if stripped.match?(/^\s*def\s+/)
                in_method = true
                method_start = index
              elsif stripped == 'end' && in_method
                method_length = index - method_start + 1
                method_lengths << method_length
                in_method = false
              end
            end
          rescue => e
            puts "Warning: Could not analyze method lengths for #{file}: #{e.message}" if config.verbose
          end
        end
        
        return { methods_found: 0 } if method_lengths.empty?
        
        {
          methods_found: method_lengths.count,
          average_length: (method_lengths.sum.to_f / method_lengths.count).round(2),
          min_length: method_lengths.min,
          max_length: method_lengths.max,
          median_length: method_lengths.sort[method_lengths.count / 2]
        }
      end

      def analyze_class_sizes(ruby_files)
        class_sizes = []
        
        ruby_files.each do |file|
          next unless File.exist?(file) && File.readable?(file)
          
          begin
            content = File.read(file)
            lines = content.lines
            
            in_class = false
            class_start = 0
            
            lines.each_with_index do |line, index|
              stripped = line.strip
              
              if stripped.match?(/^\s*class\s+/)
                in_class = true
                class_start = index
              elsif stripped == 'end' && in_class
                class_size = index - class_start + 1
                class_sizes << class_size
                in_class = false
              end
            end
          rescue => e
            puts "Warning: Could not analyze class sizes for #{file}: #{e.message}" if config.verbose
          end
        end
        
        return { classes_found: 0 } if class_sizes.empty?
        
        {
          classes_found: class_sizes.count,
          average_size: (class_sizes.sum.to_f / class_sizes.count).round(2),
          min_size: class_sizes.min,
          max_size: class_sizes.max,
          median_size: class_sizes.sort[class_sizes.count / 2]
        }
      end

      def generate_comprehensive_summary(analysis)
        basic = analysis[:basic_stats]
        code_metrics = analysis[:code_metrics]
        file_analysis = analysis[:file_analysis]
        gemfile_analysis = analysis[:gemfile_analysis]
        
        {
          total_files: basic[:total_files],
          primary_language: "Ruby",
          database_size: basic[:database_size][:human_readable],
          lines_of_code: code_metrics[:lines_of_code][:code_lines],
          total_lines: code_metrics[:lines_of_code][:total_lines],
          comment_ratio: "#{code_metrics[:lines_of_code][:comment_ratio]}%",
          average_file_size: code_metrics[:average_file_size][:human_readable],
          most_common_extension: file_analysis[:file_types].max_by { |_, count| count }&.first,
          largest_directory: analysis[:file_analysis][:directory_distribution].first&.first,
          total_methods: code_metrics[:method_density][:total_methods],
          total_classes: code_metrics[:class_distribution][:total_classes],
          total_modules: code_metrics[:class_distribution][:total_modules],
          gemfile_count: gemfile_analysis[:gemfile_count],
          complexity_score: analysis[:complexity_analysis][:cyclomatic_complexity][:average_complexity]
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

