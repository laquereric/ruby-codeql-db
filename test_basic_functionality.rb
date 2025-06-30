#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for basic RubyCodeqlDb functionality
require_relative "lib/ruby_codeql_db"

puts "Testing RubyCodeqlDb Gem Basic Functionality"
puts "=" * 50

# Test 1: Basic module loading
puts "\n1. Testing module loading..."
puts "✓ RubyCodeqlDb module loaded successfully"
puts "  - Version: #{RubyCodeqlDb::VERSION}"
puts "  - Configuration class: #{RubyCodeqlDb::Configuration}"
puts "  - Database::Manager class: #{RubyCodeqlDb::Database::Manager}"
puts "  - Statistics::Analyzer class: #{RubyCodeqlDb::Statistics::Analyzer}"
puts "  - CLI::Wrapper class: #{RubyCodeqlDb::CLI::Wrapper}"

# Test 2: Configuration
puts "\n2. Testing configuration..."
config = RubyCodeqlDb::Configuration.new
puts "✓ Configuration created successfully"
puts "  - Default database path: #{config.default_database_path}"
puts "  - Language: #{config.language}"
puts "  - Threads: #{config.threads}"

# Test 3: CLI Wrapper
puts "\n3. Testing CLI wrapper..."
cli = RubyCodeqlDb::CLI::Wrapper.new(config)
puts "✓ CLI wrapper created successfully"
puts "  - CLI path: #{config.codeql_cli_path}"

# Test 4: Database Manager
puts "\n4. Testing database manager..."
manager = RubyCodeqlDb::Database::Manager.new(config)
puts "✓ Database manager created successfully"

# Test 5: Statistics Analyzer
puts "\n5. Testing statistics analyzer..."
analyzer = RubyCodeqlDb::Statistics::Analyzer.new(config)
puts "✓ Statistics analyzer created successfully"

# Test 6: Global configuration
puts "\n6. Testing global configuration..."
RubyCodeqlDb.configure do |config|
  config.verbose = true
  config.threads = 2
end
puts "✓ Global configuration set successfully"
puts "  - Verbose: #{RubyCodeqlDb.configuration.verbose}"
puts "  - Threads: #{RubyCodeqlDb.configuration.threads}"

puts "\n" + "=" * 50
puts "✓ All basic functionality tests passed!"
puts "RubyCodeqlDb gem is ready for use."

