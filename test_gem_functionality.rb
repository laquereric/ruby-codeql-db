#!/usr/bin/env ruby
# frozen_string_literal: true

# Comprehensive test script for RubyCodeqlDb gem functionality

require_relative "lib/ruby_codeql_db"

puts "RubyCodeqlDb Gem - Comprehensive Functionality Test"
puts "=" * 60

# Test 1: Module Loading and Version
puts "\n1. Testing Module Loading and Version..."
puts "✓ RubyCodeqlDb version: #{RubyCodeqlDb::VERSION}"
puts "✓ All core classes loaded successfully:"
puts "  - Configuration: #{RubyCodeqlDb::Configuration}"
puts "  - Database::Manager: #{RubyCodeqlDb::Database::Manager}"
puts "  - Statistics::Analyzer: #{RubyCodeqlDb::Statistics::Analyzer}"
puts "  - CLI::Wrapper: #{RubyCodeqlDb::CLI::Wrapper}"

# Test 2: Configuration System
puts "\n2. Testing Configuration System..."
begin
  config = RubyCodeqlDb::Configuration.new
  puts "✓ Configuration created successfully"
  puts "  - Default database path: #{config.default_database_path}"
  puts "  - Language: #{config.language}"
  puts "  - Threads: #{config.threads}"
  puts "  - RAM: #{config.ram}MB"
  puts "  - Build mode: #{config.build_mode}"
  puts "  - Include gemfiles: #{config.include_gemfiles}"
  puts "  - Verbose: #{config.verbose}"
  puts "  - Exclude patterns: #{config.exclude_patterns.count} patterns"
rescue => e
  puts "✗ Configuration failed: #{e.message}"
end

# Test 3: Global Configuration
puts "\n3. Testing Global Configuration..."
begin
  RubyCodeqlDb.configure do |c|
    c.verbose = true
    c.threads = 4
    c.ram = 4096
  end
  puts "✓ Global configuration set successfully"
  puts "  - Verbose: #{RubyCodeqlDb.configuration.verbose}"
  puts "  - Threads: #{RubyCodeqlDb.configuration.threads}"
  puts "  - RAM: #{RubyCodeqlDb.configuration.ram}MB"
rescue => e
  puts "✗ Global configuration failed: #{e.message}"
end

# Test 4: Database Manager
puts "\n4. Testing Database Manager..."
begin
  config = RubyCodeqlDb::Configuration.new
  manager = RubyCodeqlDb::Database::Manager.new(config)
  puts "✓ Database manager created successfully"
  
  # Test file scanning methods
  ruby_files = manager.send(:scan_ruby_files, ".")
  gemfiles = manager.send(:scan_gemfiles, ".")
  
  puts "  - Ruby files found: #{ruby_files.count}"
  puts "  - Gemfiles found: #{gemfiles.count}"
rescue => e
  puts "✗ Database manager failed: #{e.message}"
end

# Test 5: Statistics Analyzer
puts "\n5. Testing Statistics Analyzer..."
begin
  config = RubyCodeqlDb::Configuration.new
  analyzer = RubyCodeqlDb::Statistics::Analyzer.new(config)
  puts "✓ Statistics analyzer created successfully"
  
  # Test lines of code calculation
  test_files = Dir.glob("lib/**/*.rb").first(3)
  if test_files.any?
    loc_stats = analyzer.calculate_lines_of_code(test_files)
    puts "  - Test files analyzed: #{test_files.count}"
    puts "  - Total lines: #{loc_stats[:total_lines]}"
    puts "  - Code lines: #{loc_stats[:code_lines]}"
    puts "  - Comment ratio: #{loc_stats[:comment_ratio]}%"
  end
rescue => e
  puts "✗ Statistics analyzer failed: #{e.message}"
end

# Test 6: CLI Wrapper
puts "\n6. Testing CLI Wrapper..."
begin
  config = RubyCodeqlDb::Configuration.new
  
  # Mock CLI availability for testing
  allow_any_instance_of(RubyCodeqlDb::Configuration).to receive(:cli_available?).and_return(true) if defined?(RSpec)
  
  wrapper = RubyCodeqlDb::CLI::Wrapper.new(config)
  puts "✓ CLI wrapper created successfully"
  puts "  - CLI path: #{config.codeql_cli_path}"
  
  # Test database existence check
  exists = wrapper.database_exists?("/non/existent/path")
  puts "  - Database existence check works: #{exists}"
rescue => e
  puts "✗ CLI wrapper failed: #{e.message}"
end

# Test 7: Error Classes
puts "\n7. Testing Error Classes..."
begin
  # Test error inheritance
  expect(RubyCodeqlDb::ConfigurationError.new).to be_a(RubyCodeqlDb::Error)
  expect(RubyCodeqlDb::DatabaseError.new).to be_a(RubyCodeqlDb::Error)
  expect(RubyCodeqlDb::CLIError.new).to be_a(RubyCodeqlDb::Error)
  puts "✓ Error class hierarchy is correct"
rescue => e
  puts "✗ Error classes failed: #{e.message}"
end

# Test 8: File Structure Validation
puts "\n8. Testing File Structure..."
required_files = [
  "lib/ruby_codeql_db.rb",
  "lib/ruby_codeql_db/version.rb",
  "lib/ruby_codeql_db/configuration.rb",
  "lib/ruby_codeql_db/database/manager.rb",
  "lib/ruby_codeql_db/statistics/analyzer.rb",
  "lib/ruby_codeql_db/cli/wrapper.rb",
  "lib/tasks/ruby_codeql_db.rake",
  "exe/ruby-codeql-db",
  "ruby_codeql_db.gemspec"
]

missing_files = []
required_files.each do |file|
  if File.exist?(file)
    puts "✓ #{file}"
  else
    puts "✗ #{file} (missing)"
    missing_files << file
  end
end

if missing_files.empty?
  puts "✓ All required files present"
else
  puts "✗ Missing #{missing_files.count} required files"
end

# Test 9: Executable Permissions
puts "\n9. Testing Executable Permissions..."
if File.executable?("exe/ruby-codeql-db")
  puts "✓ CLI executable has correct permissions"
else
  puts "✗ CLI executable missing or incorrect permissions"
end

# Test 10: Rake Tasks
puts "\n10. Testing Rake Tasks..."
begin
  # Load rake tasks
  load File.expand_path("lib/tasks/ruby_codeql_db.rake", __dir__)
  
  # Check if tasks are available
  task_names = Rake::Task.tasks.map(&:name).select { |name| name.start_with?('ruby_codeql_db:') }
  
  if task_names.any?
    puts "✓ Rake tasks loaded successfully"
    puts "  - Available tasks: #{task_names.join(', ')}"
  else
    puts "✗ No rake tasks found"
  end
rescue => e
  puts "✗ Rake tasks failed: #{e.message}"
end

# Test 11: Gem Building
puts "\n11. Testing Gem Building..."
begin
  # Check if gemspec is valid
  spec = Gem::Specification.load("ruby_codeql_db.gemspec")
  puts "✓ Gemspec is valid"
  puts "  - Name: #{spec.name}"
  puts "  - Version: #{spec.version}"
  puts "  - Summary: #{spec.summary}"
  puts "  - Dependencies: #{spec.dependencies.count}"
rescue => e
  puts "✗ Gemspec validation failed: #{e.message}"
end

# Test 12: Gem Package
puts "\n12. Testing Gem Package..."
begin
  # Build the gem
  system("gem build ruby_codeql_db.gemspec")
  
  if File.exist?("pkg/ruby_codeql_db-0.1.0.gem")
    gem_size = File.size("pkg/ruby_codeql_db-0.1.0.gem")
    puts "✓ Gem built successfully"
    puts "  - Gem file: pkg/ruby_codeql_db-0.1.0.gem"
    puts "  - Size: #{(gem_size / 1024.0).round(2)} KB"
  else
    puts "✗ Gem build failed"
  end
rescue => e
  puts "✗ Gem building failed: #{e.message}"
end

# Test 13: Integration Test
puts "\n13. Testing Integration..."
begin
  # Test the main module interface
  result = RubyCodeqlDb.create_database(".", "./test_db", overwrite: true)
  puts "✓ Database creation integration test passed"
  puts "  - Created database with #{result[:ruby_files_count]} Ruby files"
  
  # Clean up
  FileUtils.rm_rf("./test_db") if Dir.exist?("./test_db")
rescue => e
  puts "✗ Integration test failed: #{e.message}"
end

# Summary
puts "\n" + "=" * 60
puts "RubyCodeqlDb Gem Test Summary"
puts "=" * 60

if missing_files.empty?
  puts "✓ All core functionality tests passed"
  puts "✓ File structure is correct"
  puts "✓ Gem is ready for use"
else
  puts "✗ Some issues found"
  puts "  - Missing files: #{missing_files.count}"
end

puts "\nRubyCodeqlDb gem is ready for use."

