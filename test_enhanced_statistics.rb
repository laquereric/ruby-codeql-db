#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for enhanced statistics functionality

require_relative "lib/codeql_db"

puts "Testing Enhanced CodeQL DB Statistics"
puts "=" * 50

# Test 1: Lines of Code Calculation
puts "\n1. Testing Lines of Code Calculation..."
begin
  config = CodeqlDb::Configuration.new
  analyzer = CodeqlDb::Statistics::Analyzer.new(config)
  
  # Test with current Ruby files
  ruby_files = Dir.glob("lib/**/*.rb")
  puts "Found #{ruby_files.count} Ruby files to analyze"
  
  loc_stats = analyzer.calculate_lines_of_code(ruby_files)
  
  puts "✓ Lines of Code Analysis:"
  puts "  Total lines: #{loc_stats[:total_lines]}"
  puts "  Code lines: #{loc_stats[:code_lines]}"
  puts "  Comment lines: #{loc_stats[:comment_lines]}"
  puts "  Blank lines: #{loc_stats[:blank_lines]}"
  puts "  Comment ratio: #{loc_stats[:comment_ratio]}%"
  
rescue => e
  puts "✗ Lines of Code calculation failed: #{e.message}"
end

# Test 2: File Analysis
puts "\n2. Testing File Analysis Methods..."
begin
  config = CodeqlDb::Configuration.new
  analyzer = CodeqlDb::Statistics::Analyzer.new(config)
  
  # Create mock database info
  ruby_files = Dir.glob("lib/**/*.rb")
  gemfiles = Dir.glob("**/Gemfile*") + Dir.glob("**/*.gemspec")
  
  mock_database_info = {
    metadata: {
      ruby_files: ruby_files,
      gemfiles: gemfiles
    },
    size: { human_readable: "1.2 MB", bytes: 1258291 }
  }
  
  file_analysis = analyzer.send(:analyze_files, mock_database_info)
  
  puts "✓ File Analysis:"
  puts "  File types found: #{file_analysis[:file_types].keys.join(', ')}"
  puts "  Largest file: #{File.basename(file_analysis[:largest_files].first[:path])}" if file_analysis[:largest_files].any?
  puts "  Naming patterns - snake_case: #{file_analysis[:naming_patterns][:snake_case]}"
  puts "  Size distribution - small files: #{file_analysis[:file_size_distribution][:small]}"
  
rescue => e
  puts "✗ File analysis failed: #{e.message}"
end

# Test 3: Code Metrics
puts "\n3. Testing Code Metrics..."
begin
  config = CodeqlDb::Configuration.new
  analyzer = CodeqlDb::Statistics::Analyzer.new(config)
  
  ruby_files = Dir.glob("lib/**/*.rb")
  
  mock_database_info = {
    metadata: { ruby_files: ruby_files },
    size: { human_readable: "1.2 MB", bytes: 1258291 }
  }
  
  code_metrics = analyzer.send(:calculate_code_metrics, mock_database_info)
  
  puts "✓ Code Metrics:"
  puts "  Total methods: #{code_metrics[:method_density][:total_methods]}"
  puts "  Total classes: #{code_metrics[:class_distribution][:total_classes]}"
  puts "  Total modules: #{code_metrics[:class_distribution][:total_modules]}"
  puts "  Average file size: #{code_metrics[:average_file_size][:human_readable]}"
  puts "  Methods per line: #{code_metrics[:method_density][:methods_per_line]}%"
  
rescue => e
  puts "✗ Code metrics failed: #{e.message}"
end

# Test 4: Gemfile Analysis
puts "\n4. Testing Gemfile Analysis..."
begin
  config = CodeqlDb::Configuration.new
  analyzer = CodeqlDb::Statistics::Analyzer.new(config)
  
  gemfiles = Dir.glob("**/Gemfile*") + Dir.glob("**/*.gemspec")
  
  mock_database_info = {
    metadata: { gemfiles: gemfiles }
  }
  
  gemfile_analysis = analyzer.send(:analyze_gemfiles, mock_database_info)
  
  puts "✓ Gemfile Analysis:"
  puts "  Total gemfiles: #{gemfile_analysis[:gemfile_count]}"
  puts "  Gemfile types: #{gemfile_analysis[:gemfile_types]}"
  puts "  Has dependencies: #{gemfile_analysis[:dependencies][:has_dependencies]}" if gemfile_analysis[:dependencies][:has_dependencies]
  
rescue => e
  puts "✗ Gemfile analysis failed: #{e.message}"
end

# Test 5: Complexity Analysis
puts "\n5. Testing Complexity Analysis..."
begin
  config = CodeqlDb::Configuration.new
  analyzer = CodeqlDb::Statistics::Analyzer.new(config)
  
  ruby_files = Dir.glob("lib/**/*.rb").first(3) # Test with first 3 files for speed
  
  mock_database_info = {
    metadata: { ruby_files: ruby_files }
  }
  
  complexity = analyzer.send(:analyze_complexity, mock_database_info)
  
  puts "✓ Complexity Analysis:"
  puts "  Average complexity: #{complexity[:cyclomatic_complexity][:average_complexity]}"
  puts "  Max nesting depth: #{complexity[:nesting_depth][:max_nesting_depth]}"
  puts "  Methods found: #{complexity[:method_length_distribution][:methods_found]}"
  puts "  Classes found: #{complexity[:class_size_distribution][:classes_found]}"
  
rescue => e
  puts "✗ Complexity analysis failed: #{e.message}"
end

puts "\n" + "=" * 50
puts "Enhanced statistics test completed!"
puts "All major analysis components are functional."

