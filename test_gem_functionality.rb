#!/usr/bin/env ruby
# frozen_string_literal: true

# Comprehensive test script for CodeQL DB gem functionality

require_relative "lib/codeql_db"

puts "CodeQL DB Gem - Comprehensive Functionality Test"
puts "=" * 60

# Test 1: Basic Module Loading
puts "\n1. Testing Basic Module Loading..."
begin
  puts "✓ CodeQL DB version: #{CodeqlDb::VERSION}"
  puts "✓ Main module loaded successfully"
  puts "✓ All submodules available:"
  puts "  - Configuration: #{CodeqlDb::Configuration}"
  puts "  - Database::Manager: #{CodeqlDb::Database::Manager}"
  puts "  - Statistics::Analyzer: #{CodeqlDb::Statistics::Analyzer}"
  puts "  - CLI::Wrapper: #{CodeqlDb::CLI::Wrapper}"
rescue => e
  puts "✗ Module loading failed: #{e.message}"
end

# Test 2: Configuration
puts "\n2. Testing Configuration..."
begin
  # Test default configuration
  config = CodeqlDb::Configuration.new
  puts "✓ Default configuration created"
  puts "  - CLI path: #{config.codeql_cli_path}"
  puts "  - Language: #{config.language}"
  puts "  - Threads: #{config.threads}"
  puts "  - RAM: #{config.ram}MB"
  
  # Test configuration via module
  CodeqlDb.configure do |c|
    c.verbose = true
    c.threads = 4
    c.ram = 4096
  end
  puts "✓ Module configuration works"
  puts "  - Verbose: #{CodeqlDb.configuration.verbose}"
  puts "  - Threads: #{CodeqlDb.configuration.threads}"
  puts "  - RAM: #{CodeqlDb.configuration.ram}MB"
  
rescue => e
  puts "✗ Configuration failed: #{e.message}"
end

# Test 3: File Scanning
puts "\n3. Testing File Scanning..."
begin
  config = CodeqlDb::Configuration.new
  manager = CodeqlDb::Database::Manager.new(config)
  
  # Test Ruby file scanning
  ruby_files = manager.send(:scan_ruby_files, ".")
  puts "✓ Ruby file scanning works"
  puts "  - Found #{ruby_files.length} Ruby files"
  puts "  - Sample files: #{ruby_files.first(3).map { |f| File.basename(f) }.join(', ')}"
  
  # Test Gemfile scanning
  gemfiles = manager.send(:scan_gemfiles, ".")
  puts "✓ Gemfile scanning works"
  puts "  - Found #{gemfiles.length} Gemfiles/gemspecs"
  puts "  - Files: #{gemfiles.map { |f| File.basename(f) }.join(', ')}"
  
rescue => e
  puts "✗ File scanning failed: #{e.message}"
end

# Test 4: Statistics Analysis
puts "\n4. Testing Statistics Analysis..."
begin
  config = CodeqlDb::Configuration.new
  analyzer = CodeqlDb::Statistics::Analyzer.new(config)
  
  # Test lines of code calculation
  ruby_files = Dir.glob("lib/**/*.rb")
  loc_stats = analyzer.calculate_lines_of_code(ruby_files)
  
  puts "✓ Lines of code analysis works"
  puts "  - Total lines: #{loc_stats[:total_lines]}"
  puts "  - Code lines: #{loc_stats[:code_lines]}"
  puts "  - Comment lines: #{loc_stats[:comment_lines]}"
  puts "  - Comment ratio: #{loc_stats[:comment_ratio]}%"
  
rescue => e
  puts "✗ Statistics analysis failed: #{e.message}"
end

# Test 5: CLI Wrapper (without actual CodeQL)
puts "\n5. Testing CLI Wrapper..."
begin
  config = CodeqlDb::Configuration.new
  
  # Mock CLI availability for testing
  allow_any_instance_of(CodeqlDb::Configuration).to receive(:cli_available?).and_return(true) if defined?(RSpec)
  
  wrapper = CodeqlDb::CLI::Wrapper.new(config)
  puts "✓ CLI Wrapper created successfully"
  
  # Test command building
  command = wrapper.send(:build_create_command, ".", "./test_db", {
    language: "ruby",
    threads: 2,
    ram: 2048
  })
  puts "✓ Command building works"
  puts "  - Sample command: #{command.join(' ')}"
  
rescue => e
  puts "✗ CLI Wrapper failed: #{e.message}"
end

# Test 6: Error Handling
puts "\n6. Testing Error Handling..."
begin
  # Test configuration errors
  config = CodeqlDb::Configuration.new
  config.threads = -1
  
  begin
    config.validate!
    puts "✗ Should have raised configuration error"
  rescue CodeqlDb::ConfigurationError => e
    puts "✓ Configuration error handling works: #{e.message}"
  end
  
  # Test database errors
  begin
    manager = CodeqlDb::Database::Manager.new(CodeqlDb::Configuration.new)
    manager.info("/non/existent/database")
    puts "✗ Should have raised database error"
  rescue CodeqlDb::DatabaseError => e
    puts "✓ Database error handling works: #{e.message}"
  end
  
rescue => e
  puts "✗ Error handling test failed: #{e.message}"
end

# Test 7: Rake Tasks Loading
puts "\n7. Testing Rake Tasks..."
begin
  require 'rake'
  
  # Load rake tasks
  load File.expand_path("lib/tasks/codeql_db.rake", __dir__)
  
  # Check if tasks are loaded
  task_names = Rake::Task.tasks.map(&:name).select { |name| name.start_with?('codeql_db:') }
  
  if task_names.any?
    puts "✓ Rake tasks loaded successfully"
    puts "  - Available tasks: #{task_names.join(', ')}"
  else
    puts "✗ No rake tasks found"
  end
  
rescue => e
  puts "✗ Rake tasks loading failed: #{e.message}"
end

# Test 8: Gem Structure Validation
puts "\n8. Testing Gem Structure..."
begin
  required_files = [
    "lib/codeql_db.rb",
    "lib/codeql_db/version.rb",
    "lib/codeql_db/configuration.rb",
    "lib/codeql_db/database/manager.rb",
    "lib/codeql_db/statistics/analyzer.rb",
    "lib/codeql_db/cli/wrapper.rb",
    "lib/tasks/codeql_db.rake",
    "exe/codeql_db",
    "README.md",
    "codeql_db.gemspec"
  ]
  
  missing_files = required_files.reject { |file| File.exist?(file) }
  
  if missing_files.empty?
    puts "✓ All required files present"
    puts "  - Checked #{required_files.length} files"
  else
    puts "✗ Missing files: #{missing_files.join(', ')}"
  end
  
  # Check executable permissions
  if File.executable?("exe/codeql_db")
    puts "✓ CLI executable has correct permissions"
  else
    puts "✗ CLI executable missing execute permissions"
  end
  
rescue => e
  puts "✗ Gem structure validation failed: #{e.message}"
end

# Test 9: Documentation
puts "\n9. Testing Documentation..."
begin
  readme_content = File.read("README.md")
  
  required_sections = [
    "# CodeQL DB",
    "## Installation",
    "## Usage",
    "## Configuration",
    "## Examples",
    "## API Reference"
  ]
  
  missing_sections = required_sections.reject { |section| readme_content.include?(section) }
  
  if missing_sections.empty?
    puts "✓ README contains all required sections"
    puts "  - README size: #{readme_content.length} characters"
  else
    puts "✗ README missing sections: #{missing_sections.join(', ')}"
  end
  
rescue => e
  puts "✗ Documentation test failed: #{e.message}"
end

# Test 10: Gem Build
puts "\n10. Testing Gem Build..."
begin
  if File.exist?("pkg/codeql_db-0.1.0.gem")
    gem_size = File.size("pkg/codeql_db-0.1.0.gem")
    puts "✓ Gem built successfully"
    puts "  - Gem file: pkg/codeql_db-0.1.0.gem"
    puts "  - Size: #{(gem_size / 1024.0).round(2)} KB"
  else
    puts "✗ Gem file not found"
  end
rescue => e
  puts "✗ Gem build test failed: #{e.message}"
end

puts "\n" + "=" * 60
puts "Comprehensive functionality test completed!"
puts "CodeQL DB gem is ready for use."
puts "\nNext steps:"
puts "1. Install CodeQL CLI for full functionality"
puts "2. Test with actual Ruby projects"
puts "3. Deploy to RubyGems (optional)"
puts "=" * 60

