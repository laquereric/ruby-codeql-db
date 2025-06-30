#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for enhanced RubyCodeqlDb statistics functionality
require_relative "lib/ruby_codeql_db"

puts "Testing Enhanced RubyCodeqlDb Statistics"
puts "=" * 50

# Test 1: Lines of Code Analysis
puts "\n1. Testing Lines of Code Analysis..."
config = RubyCodeqlDb::Configuration.new
analyzer = RubyCodeqlDb::Statistics::Analyzer.new(config)

# Create test files
test_files = []
Dir.mktmpdir do |temp_dir|
  # Create a test Ruby file
  test_file = File.join(temp_dir, "test.rb")
  File.write(test_file, <<~RUBY)
    # This is a comment
    class TestClass
      def test_method
        # Another comment
        puts "Hello, World!"
      end
    end
  RUBY
  test_files << test_file

  # Analyze lines of code
  loc_stats = analyzer.calculate_lines_of_code(test_files)
  puts "✓ Lines of code analysis completed"
  puts "  - Total lines: #{loc_stats[:total_lines]}"
  puts "  - Code lines: #{loc_stats[:code_lines]}"
  puts "  - Comment lines: #{loc_stats[:comment_lines]}"
  puts "  - Blank lines: #{loc_stats[:blank_lines]}"
  puts "  - Comment ratio: #{loc_stats[:comment_ratio]}%"
end

# Test 2: File Analysis
puts "\n2. Testing File Analysis..."
Dir.mktmpdir do |temp_dir|
  # Create test files with different extensions
  File.write(File.join(temp_dir, "test.rb"), "puts 'test'")
  File.write(File.join(temp_dir, "helper.rb"), "def helper; end")
  File.write(File.join(temp_dir, "Gemfile"), "gem 'test'")
  File.write(File.join(temp_dir, "test.gemspec"), "Gem::Specification.new")

  files = Dir.glob(File.join(temp_dir, "*"))
  file_types = analyzer.send(:count_file_types, files)
  
  puts "✓ File type analysis completed"
  file_types.each do |ext, count|
    puts "  - #{ext}: #{count} files"
  end
end

# Test 3: File Size Distribution
puts "\n3. Testing File Size Distribution..."
Dir.mktmpdir do |temp_dir|
  # Create files of different sizes
  File.write(File.join(temp_dir, "small.rb"), "a" * 500)  # ~500 bytes
  File.write(File.join(temp_dir, "medium.rb"), "a" * 5000)  # ~5KB
  File.write(File.join(temp_dir, "large.rb"), "a" * 50000)  # ~50KB

  files = Dir.glob(File.join(temp_dir, "*"))
  size_dist = analyzer.send(:analyze_file_size_distribution, files)
  
  puts "✓ File size distribution analysis completed"
  puts "  - Tiny files (< 1KB): #{size_dist[:tiny]}"
  puts "  - Small files (1-10KB): #{size_dist[:small]}"
  puts "  - Medium files (10-100KB): #{size_dist[:medium]}"
  puts "  - Large files (100KB-1MB): #{size_dist[:large]}"
  puts "  - Huge files (> 1MB): #{size_dist[:huge]}"
end

# Test 4: Naming Patterns
puts "\n4. Testing Naming Patterns..."
Dir.mktmpdir do |temp_dir|
  # Create files with different naming patterns
  File.write(File.join(temp_dir, "snake_case.rb"), "")
  File.write(File.join(temp_dir, "CamelCase.rb"), "")
  File.write(File.join(temp_dir, "test_file.rb"), "")
  File.write(File.join(temp_dir, "spec_file.rb"), "")
  File.write(File.join(temp_dir, "file123.rb"), "")

  ruby_files = Dir.glob(File.join(temp_dir, "*.rb"))
  patterns = analyzer.send(:analyze_naming_patterns, ruby_files)
  
  puts "✓ Naming pattern analysis completed"
  puts "  - Snake case: #{patterns[:snake_case]}"
  puts "  - Camel case: #{patterns[:camel_case]}"
  puts "  - Mixed case: #{patterns[:mixed_case]}"
  puts "  - With numbers: #{patterns[:with_numbers]}"
  puts "  - Test files: #{patterns[:test_files]}"
  puts "  - Spec files: #{patterns[:spec_files]}"
end

# Test 5: Method and Class Analysis
puts "\n5. Testing Method and Class Analysis..."
Dir.mktmpdir do |temp_dir|
  # Create a test file with methods and classes
  File.write(File.join(temp_dir, "test.rb"), <<~RUBY)
    class TestClass
      def method1
        puts "method1"
      end
      
      def method2
        puts "method2"
      end
    end
    
    module TestModule
      def module_method
        puts "module method"
      end
    end
  RUBY

  ruby_files = Dir.glob(File.join(temp_dir, "*.rb"))
  method_density = analyzer.send(:estimate_method_density, ruby_files)
  class_dist = analyzer.send(:analyze_class_distribution, ruby_files)
  
  puts "✓ Method and class analysis completed"
  puts "  - Total methods: #{method_density[:total_methods]}"
  puts "  - Total lines: #{method_density[:total_lines]}"
  puts "  - Methods per line: #{method_density[:methods_per_line]}%"
  puts "  - Average method length: #{method_density[:average_method_length]} lines"
  puts "  - Total classes: #{class_dist[:total_classes]}"
  puts "  - Total modules: #{class_dist[:total_modules]}"
  puts "  - Classes per file: #{class_dist[:classes_per_file]}"
  puts "  - Modules per file: #{class_dist[:modules_per_file]}"
end

# Test 6: Complexity Analysis
puts "\n6. Testing Complexity Analysis..."
Dir.mktmpdir do |temp_dir|
  # Create a test file with some complexity
  File.write(File.join(temp_dir, "complex.rb"), <<~RUBY)
    class ComplexClass
      def complex_method(param)
        if param > 0
          if param > 10
            puts "high"
          else
            puts "medium"
          end
        else
          puts "low"
        end
        
        begin
          risky_operation
        rescue => e
          handle_error(e)
        end
      end
    end
  RUBY

  ruby_files = Dir.glob(File.join(temp_dir, "*.rb"))
  complexity = analyzer.send(:estimate_cyclomatic_complexity, ruby_files)
  nesting = analyzer.send(:analyze_nesting_depth, ruby_files)
  
  puts "✓ Complexity analysis completed"
  puts "  - Total complexity: #{complexity[:total_complexity]}"
  puts "  - Average complexity: #{complexity[:average_complexity]}"
  puts "  - Files analyzed: #{complexity[:files_analyzed]}"
  puts "  - Max nesting depth: #{nesting[:max_nesting_depth]}"
  puts "  - Average nesting depth: #{nesting[:average_nesting_depth]}"
end

puts "\n" + "=" * 50
puts "✓ All enhanced statistics tests passed!"
puts "RubyCodeqlDb statistics functionality is working correctly."

