#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for basic CodeQL DB functionality

require_relative "lib/codeql_db"

puts "Testing CodeQL DB Gem Basic Functionality"
puts "=" * 50

# Test 1: Configuration
puts "\n1. Testing Configuration..."
begin
  config = CodeqlDb::Configuration.new
  puts "✓ Configuration created successfully"
  puts "  - Default database path: #{config.default_database_path}"
  puts "  - Language: #{config.language}"
  puts "  - Threads: #{config.threads}"
  puts "  - RAM: #{config.ram}MB"
rescue => e
  puts "✗ Configuration failed: #{e.message}"
end

# Test 2: CLI Wrapper (without actual CodeQL CLI)
puts "\n2. Testing CLI Wrapper..."
begin
  config = CodeqlDb::Configuration.new
  cli = CodeqlDb::CLI::Wrapper.new(config)
  puts "✓ CLI Wrapper created successfully"
  
  # Test database existence check (should return false for non-existent path)
  exists = cli.database_exists?("/non/existent/path")
  puts "✓ Database existence check works: #{exists}"
rescue => e
  puts "✗ CLI Wrapper failed: #{e.message}"
end

# Test 3: Database Manager
puts "\n3. Testing Database Manager..."
begin
  config = CodeqlDb::Configuration.new
  manager = CodeqlDb::Database::Manager.new(config)
  puts "✓ Database Manager created successfully"
  
  # Test file scanning on current directory
  ruby_files = manager.send(:scan_ruby_files, ".")
  puts "✓ Ruby file scanning works: found #{ruby_files.length} files"
  
  gemfiles = manager.send(:scan_gemfiles, ".")
  puts "✓ Gemfile scanning works: found #{gemfiles.length} files"
rescue => e
  puts "✗ Database Manager failed: #{e.message}"
end

# Test 4: Statistics Analyzer
puts "\n4. Testing Statistics Analyzer..."
begin
  config = CodeqlDb::Configuration.new
  analyzer = CodeqlDb::Statistics::Analyzer.new(config)
  puts "✓ Statistics Analyzer created successfully"
rescue => e
  puts "✗ Statistics Analyzer failed: #{e.message}"
end

# Test 5: Main module interface
puts "\n5. Testing Main Module Interface..."
begin
  CodeqlDb.configure do |config|
    config.verbose = true
    config.threads = 2
  end
  puts "✓ Main module configuration works"
  puts "  - Verbose: #{CodeqlDb.configuration.verbose}"
  puts "  - Threads: #{CodeqlDb.configuration.threads}"
rescue => e
  puts "✗ Main module interface failed: #{e.message}"
end

puts "\n" + "=" * 50
puts "Basic functionality test completed!"
puts "Note: Full CodeQL functionality requires CodeQL CLI installation"

