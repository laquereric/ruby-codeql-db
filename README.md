# CodeqlDb

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/codeql_db`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternativ# CodeQL DB - Comprehensive CodeQL Database Management for Ruby

[![Gem Version](https://badge.fury.io/rb/codeql_db.svg)](https://badge.fury.io/rb/codeql_db)
[![Build Status](https://github.com/example/codeql_db/workflows/CI/badge.svg)](https://github.com/example/codeql_db/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

CodeQL DB is a comprehensive Ruby gem that provides seamless integration with GitHub's CodeQL static analysis engine. It enables Ruby developers and Rails applications to create, manage, and analyze CodeQL databases with ease, offering powerful insights into code quality, security vulnerabilities, and project statistics.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Command Line Interface](#command-line-interface)
  - [Rake Tasks](#rake-tasks)
  - [Programmatic API](#programmatic-api)
  - [Rails Integration](#rails-integration)
- [Statistics and Analysis](#statistics-and-analysis)
- [Examples](#examples)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [License](#license)

## Features

### Core Functionality
- **Database Creation**: Automatically create CodeQL databases from Ruby projects
- **File Discovery**: Intelligent scanning of Ruby files, Gemfiles, and gemspecs
- **Database Management**: Create, list, analyze, and delete CodeQL databases
- **Cross-Platform**: Works on Linux, macOS, and Windows

### Analysis Capabilities
- **Lines of Code Analysis**: Comprehensive counting of code, comments, and blank lines
- **Complexity Metrics**: Cyclomatic complexity and nesting depth analysis
- **File Statistics**: Size distribution, naming patterns, and type analysis
- **Gemfile Analysis**: Dependency analysis and gemspec examination
- **Method and Class Distribution**: Detailed code structure analysis

### Integration Options
- **Command Line Interface**: Full-featured CLI using Thor
- **Rake Tasks**: Convenient rake tasks for common operations
- **Rails Integration**: Automatic integration with Rails applications
- **Programmatic API**: Ruby API for custom integrations

### Advanced Features
- **Configurable Exclusions**: Customize which files and directories to exclude
- **Performance Optimization**: Multi-threaded processing and memory management
- **Detailed Reporting**: Comprehensive statistics and analysis reports
- **Error Handling**: Robust error handling and validation

## Installation

### Prerequisites

Before installing CodeQL DB, ensure you have:

1. **Ruby 3.0+**: The gem requires Ruby 3.0 or later
2. **CodeQL CLI**: Download and install the CodeQL CLI from [GitHub](https://github.com/github/codeql-cli-binaries/releases)

### Installing CodeQL CLI

```bash
# Download CodeQL CLI (example for Linux)
wget https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip
unzip codeql-linux64.zip
sudo mv codeql /usr/local/bin/

# Verify installation
codeql version
```

### Installing the Gem

Add this line to your application's Gemfile:

```ruby
gem 'codeql_db'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install codeql_db
```

## Quick Start

### Basic Usage

```ruby
require 'codeql_db'

# Configure the gem
CodeqlDb.configure do |config|
  config.verbose = true
  config.threads = 4
  config.ram = 4096
end

# Create a database
result = CodeqlDb.create_database(".", "./my_codeql_db")
puts "Created database with #{result[:ruby_files_count]} Ruby files"

# Analyze the database
analysis = CodeqlDb.analyze_database("./my_codeql_db")
puts "Total lines of code: #{analysis[:summary][:lines_of_code]}"
```

### Command Line Usage

```bash
# Create a database
codeql_db create . ./my_database --verbose

# List files in database
codeql_db list ./my_database --include-files

# Analyze database
codeql_db analyze ./my_database

# Get database info
codeql_db info ./my_database

# Delete database
codeql_db delete ./my_database --force
```

### Rake Tasks

```bash
# Create database
rake codeql_db:create[.,my_database] VERBOSE=true

# List files
rake codeql_db:list[my_database] INCLUDE_FILES=true

# Analyze database
rake codeql_db:analyze[my_database]

# Show help
rake codeql_db:help
```

## Configuration

CodeQL DB provides extensive configuration options to customize its behavior:

### Basic Configuration

```ruby
CodeqlDb.configure do |config|
  # CodeQL CLI path (auto-detected by default)
  config.codeql_cli_path = "/usr/local/bin/codeql"
  
  # Default database path
  config.default_database_path = "./codeql_db"
  
  # Source root directory
  config.source_root = "."
  
  # Target language
  config.language = "ruby"
  
  # Performance settings
  config.threads = 2
  config.ram = 2048  # MB
  
  # Build mode (none for Ruby)
  config.build_mode = "none"
  
  # Include Gemfiles in analysis
  config.include_gemfiles = true
  
  # Enable verbose output
  config.verbose = false
end
```

### Exclusion Patterns

```ruby
CodeqlDb.configure do |config|
  config.exclude_patterns = %w[
    .git
    node_modules
    vendor/bundle
    tmp
    log
    coverage
    .bundle
    public/assets
    storage
  ]
end
```

### Rails-Specific Configuration

For Rails applications, CodeQL DB automatically configures sensible defaults:

```ruby
# In a Rails initializer (config/initializers/codeql_db.rb)
CodeqlDb.configure do |config|
  config.source_root = Rails.root.to_s
  config.default_database_path = Rails.root.join("tmp", "codeql_db").to_s
  config.exclude_patterns += %w[
    public/assets
    public/packs
    storage
    tmp/cache
    db/migrate
  ]
end
```

## Usage

### Command Line Interface

The CodeQL DB CLI provides a comprehensive command-line interface for all operations:

#### Creating Databases

```bash
# Basic database creation
codeql_db create

# Specify source and database paths
codeql_db create /path/to/source /path/to/database

# With options
codeql_db create . ./db --verbose --threads 4 --ram 4096 --overwrite
```

#### Listing and Analyzing

```bash
# List files in database
codeql_db list ./database

# Include detailed file list
codeql_db list ./database --include-files

# Include statistics
codeql_db list ./database --include-stats

# Full analysis
codeql_db analyze ./database
```

#### Database Management

```bash
# Get database information
codeql_db info ./database

# Delete database
codeql_db delete ./database

# Force delete without confirmation
codeql_db delete ./database --force

# Show version
codeql_db version
```

### Rake Tasks

CodeQL DB provides comprehensive rake tasks for integration with Ruby projects:

#### Available Tasks

```bash
rake codeql_db:create[source_path,database_path]  # Create a CodeQL database
rake codeql_db:list[database_path]                # List files in database
rake codeql_db:analyze[database_path]             # Analyze database
rake codeql_db:info[database_path]                # Show database info
rake codeql_db:delete[database_path]              # Delete database
rake codeql_db:help                               # Show help
```

#### Environment Variables

Rake tasks support various environment variables for configuration:

```bash
# For creation
VERBOSE=true THREADS=4 RAM=4096 OVERWRITE=true rake codeql_db:create

# For listing
INCLUDE_FILES=true INCLUDE_STATS=true rake codeql_db:list

# For deletion
FORCE=true rake codeql_db:delete
```

### Programmatic API

The Ruby API provides full programmatic access to CodeQL DB functionality:

#### Database Operations

```ruby
# Create database
result = CodeqlDb.create_database(
  source_path: "./src",
  database_path: "./db",
  options: {
    overwrite: true,
    verbose: true
  }
)

# List files
files_info = CodeqlDb.list_files(
  database_path: "./db",
  options: {
    include_file_list: true,
    include_stats: true
  }
)

# Analyze database
analysis = CodeqlDb.analyze_database("./db")
```

#### Advanced Usage

```ruby
# Direct manager access
config = CodeqlDb::Configuration.new
manager = CodeqlDb::Database::Manager.new(config)

# Create with custom options
result = manager.create(
  source_path: "./src",
  database_path: "./db",
  options: {
    overwrite: true,
    extractor_options: {
      "ruby.extraction.timeout" => "300"
    }
  }
)

# Get detailed info
info = manager.info("./db")
puts "Database size: #{info[:size][:human_readable]}"
```

#### Statistics Analysis

```ruby
# Detailed statistics
config = CodeqlDb::Configuration.new
analyzer = CodeqlDb::Statistics::Analyzer.new(config)

# Lines of code analysis
ruby_files = Dir.glob("**/*.rb")
loc_stats = analyzer.calculate_lines_of_code(ruby_files)

puts "Code lines: #{loc_stats[:code_lines]}"
puts "Comment ratio: #{loc_stats[:comment_ratio]}%"
```

### Rails Integration

CodeQL DB seamlessly integrates with Rails applications through a Railtie:

#### Automatic Configuration

When used in a Rails application, CodeQL DB automatically:

- Sets the source root to `Rails.root`
- Configures the default database path to `tmp/codeql_db`
- Excludes Rails-specific directories
- Loads rake tasks automatically

#### Rails Initializer

Create an initializer for custom configuration:

```ruby
# config/initializers/codeql_db.rb
CodeqlDb.configure do |config|
  config.verbose = Rails.env.development?
  config.threads = Rails.env.production? ? 4 : 2
  config.ram = Rails.env.production? ? 4096 : 2048
  
  # Custom exclusions for your Rails app
  config.exclude_patterns += %w[
    app/assets/images
    vendor/assets
    node_modules
  ]
end
```

#### Usage in Rails

```ruby
# In a Rails controller or service
class CodeAnalysisService
  def self.analyze_application
    database_path = Rails.root.join("tmp", "codeql_analysis")
    
    # Create database
    result = CodeqlDb.create_database(
      Rails.root.to_s,
      database_path.to_s,
      overwrite: true
    )
    
    # Analyze
    analysis = CodeqlDb.analyze_database(database_path.to_s)
    
    {
      files_analyzed: result[:ruby_files_count],
      lines_of_code: analysis[:summary][:lines_of_code],
      complexity: analysis[:summary][:complexity_score]
    }
  end
end
```

## Statistics and Analysis

CodeQL DB provides comprehensive code analysis and statistics generation:

### Lines of Code Analysis

```ruby
analysis = CodeqlDb.analyze_database("./database")
loc = analysis[:code_metrics][:lines_of_code]

puts "Total lines: #{loc[:total_lines]}"
puts "Code lines: #{loc[:code_lines]}"
puts "Comment lines: #{loc[:comment_lines]}"
puts "Blank lines: #{loc[:blank_lines]}"
puts "Comment ratio: #{loc[:comment_ratio]}%"
```

### File Analysis

```ruby
file_analysis = analysis[:file_analysis]

# File type distribution
file_analysis[:file_types].each do |ext, count|
  puts "#{ext}: #{count} files"
end

# Size distribution
size_dist = file_analysis[:file_size_distribution]
puts "Small files (1-10KB): #{size_dist[:small]}"
puts "Medium files (10-100KB): #{size_dist[:medium]}"
puts "Large files (100KB+): #{size_dist[:large]}"

# Naming patterns
patterns = file_analysis[:naming_patterns]
puts "Snake case files: #{patterns[:snake_case]}"
puts "Test files: #{patterns[:test_files]}"
puts "Spec files: #{patterns[:spec_files]}"
```

### Complexity Analysis

```ruby
complexity = analysis[:complexity_analysis]

# Cyclomatic complexity
cc = complexity[:cyclomatic_complexity]
puts "Average complexity: #{cc[:average_complexity]}"
puts "Total complexity: #{cc[:total_complexity]}"

# Nesting depth
nesting = complexity[:nesting_depth]
puts "Max nesting depth: #{nesting[:max_nesting_depth]}"
puts "Average nesting: #{nesting[:average_nesting_depth]}"

# Method analysis
methods = complexity[:method_length_distribution]
puts "Methods found: #{methods[:methods_found]}"
puts "Average method length: #{methods[:average_length]} lines"
puts "Longest method: #{methods[:max_length]} lines"
```

### Gemfile Analysis

```ruby
gemfile_analysis = analysis[:gemfile_analysis]

puts "Total gemfiles: #{gemfile_analysis[:gemfile_count]}"

# Gemfile types
gemfile_analysis[:gemfile_types].each do |type, count|
  puts "#{type}: #{count}"
end

# Dependencies (if Gemfile analyzed)
deps = gemfile_analysis[:dependencies]
if deps[:total_gems]
  puts "Total gems: #{deps[:total_gems]}"
  puts "Has git dependencies: #{deps[:has_git_dependencies]}"
  puts "Has path dependencies: #{deps[:has_path_dependencies]}"
end
```

## Examples

### Example 1: Basic Project Analysis

```ruby
require 'codeql_db'

# Configure for a typical Ruby project
CodeqlDb.configure do |config|
  config.verbose = true
  config.threads = 4
end

# Create and analyze database
puts "Creating CodeQL database..."
result = CodeqlDb.create_database(".", "./analysis_db")

puts "Database created successfully!"
puts "  Ruby files: #{result[:ruby_files_count]}"
puts "  Gemfiles: #{result[:gemfiles_count]}"
puts "  Database path: #{result[:database_path]}"

# Perform analysis
puts "\nAnalyzing database..."
analysis = CodeqlDb.analyze_database("./analysis_db")

# Display key metrics
summary = analysis[:summary]
puts "\nProject Summary:"
puts "  Total files: #{summary[:total_files]}"
puts "  Lines of code: #{summary[:lines_of_code]}"
puts "  Comment ratio: #{summary[:comment_ratio]}"
puts "  Average complexity: #{summary[:complexity_score]}"
puts "  Total methods: #{summary[:total_methods]}"
puts "  Total classes: #{summary[:total_classes]}"
```

### Example 2: Rails Application Analysis

```ruby
# In a Rails application
class ApplicationAnalyzer
  def self.generate_report
    database_path = Rails.root.join("tmp", "codeql_analysis")
    
    begin
      # Create database
      result = CodeqlDb.create_database(
        Rails.root.to_s,
        database_path.to_s,
        overwrite: true
      )
      
      # Analyze
      analysis = CodeqlDb.analyze_database(database_path.to_s)
      
      # Generate report
      report = {
        timestamp: Time.current,
        application: Rails.application.class.module_parent_name,
        environment: Rails.env,
        analysis: {
          files_count: result[:ruby_files_count],
          lines_of_code: analysis[:summary][:lines_of_code],
          complexity_score: analysis[:summary][:complexity_score],
          test_coverage: calculate_test_coverage(analysis),
          code_quality_score: calculate_quality_score(analysis)
        }
      }
      
      # Save report
      File.write(
        Rails.root.join("tmp", "code_analysis_report.json"),
        JSON.pretty_generate(report)
      )
      
      report
    ensure
      # Cleanup
      FileUtils.rm_rf(database_path) if File.exist?(database_path)
    end
  end
  
  private
  
  def self.calculate_test_coverage(analysis)
    file_analysis = analysis[:file_analysis]
    naming_patterns = file_analysis[:naming_patterns]
    
    total_files = analysis[:basic_stats][:ruby_files]
    test_files = naming_patterns[:test_files] + naming_patterns[:spec_files]
    
    return 0 if total_files == 0
    (test_files.to_f / total_files * 100).round(2)
  end
  
  def self.calculate_quality_score(analysis)
    # Simple quality score based on various metrics
    comment_ratio = analysis[:code_metrics][:lines_of_code][:comment_ratio]
    complexity = analysis[:summary][:complexity_score]
    
    # Higher comment ratio is better, lower complexity is better
    comment_score = [comment_ratio / 20.0, 1.0].min * 40
    complexity_score = [1.0 / (complexity / 10.0), 1.0].min * 60
    
    (comment_score + complexity_score).round(2)
  end
end
```

### Example 3: Continuous Integration Integration

```ruby
# ci_analysis.rb - For use in CI/CD pipelines
require 'codeql_db'

class CIAnalysis
  def self.run
    puts "Starting CodeQL analysis for CI..."
    
    # Configure for CI environment
    CodeqlDb.configure do |config|
      config.verbose = ENV['CI_VERBOSE'] == 'true'
      config.threads = ENV['CI_THREADS']&.to_i || 2
      config.ram = ENV['CI_RAM']&.to_i || 2048
    end
    
    database_path = "./ci_codeql_db"
    
    begin
      # Create database
      result = CodeqlDb.create_database(".", database_path, overwrite: true)
      
      # Analyze
      analysis = CodeqlDb.analyze_database(database_path)
      
      # Check quality gates
      quality_checks = perform_quality_checks(analysis)
      
      # Output results
      output_ci_results(analysis, quality_checks)
      
      # Exit with appropriate code
      exit(quality_checks[:passed] ? 0 : 1)
      
    rescue => e
      puts "ERROR: CodeQL analysis failed: #{e.message}"
      exit(1)
    ensure
      FileUtils.rm_rf(database_path) if File.exist?(database_path)
    end
  end
  
  private
  
  def self.perform_quality_checks(analysis)
    checks = {
      passed: true,
      results: {}
    }
    
    # Check complexity
    complexity = analysis[:summary][:complexity_score]
    complexity_threshold = ENV['COMPLEXITY_THRESHOLD']&.to_f || 15.0
    
    checks[:results][:complexity] = {
      value: complexity,
      threshold: complexity_threshold,
      passed: complexity <= complexity_threshold
    }
    
    # Check comment ratio
    comment_ratio = analysis[:code_metrics][:lines_of_code][:comment_ratio]
    comment_threshold = ENV['COMMENT_THRESHOLD']&.to_f || 10.0
    
    checks[:results][:comments] = {
      value: comment_ratio,
      threshold: comment_threshold,
      passed: comment_ratio >= comment_threshold
    }
    
    # Overall pass/fail
    checks[:passed] = checks[:results].values.all? { |check| check[:passed] }
    
    checks
  end
  
  def self.output_ci_results(analysis, quality_checks)
    puts "\n" + "="*50
    puts "CodeQL Analysis Results"
    puts "="*50
    
    summary = analysis[:summary]
    puts "Files analyzed: #{summary[:total_files]}"
    puts "Lines of code: #{summary[:lines_of_code]}"
    puts "Total methods: #{summary[:total_methods]}"
    puts "Total classes: #{summary[:total_classes]}"
    
    puts "\nQuality Checks:"
    quality_checks[:results].each do |check_name, result|
      status = result[:passed] ? "✓ PASS" : "✗ FAIL"
      puts "  #{check_name.capitalize}: #{result[:value]} (threshold: #{result[:threshold]}) #{status}"
    end
    
    puts "\nOverall: #{quality_checks[:passed] ? '✓ PASSED' : '✗ FAILED'}"
  end
end

# Run if called directly
CIAnalysis.run if __FILE__ == $0
```

## API Reference

### CodeqlDb Module

#### Configuration

```ruby
CodeqlDb.configure { |config| ... }  # Configure the gem
CodeqlDb.configuration               # Access current configuration
```

#### Database Operations

```ruby
CodeqlDb.create_database(source_path, database_path = nil, options = {})
CodeqlDb.analyze_database(database_path, options = {})
CodeqlDb.list_files(database_path, options = {})
```

### CodeqlDb::Configuration

#### Attributes

- `codeql_cli_path` - Path to CodeQL CLI executable
- `default_database_path` - Default database location
- `source_root` - Source code root directory
- `language` - Target programming language
- `threads` - Number of processing threads
- `ram` - Memory allocation in MB
- `build_mode` - Build mode for compilation
- `include_gemfiles` - Include Gemfiles in analysis
- `exclude_patterns` - Array of exclusion patterns
- `verbose` - Enable verbose output

#### Methods

```ruby
config.validate!           # Validate configuration
config.cli_available?       # Check if CodeQL CLI is available
config.valid_language?      # Check if language is supported
config.database_path(path)  # Get database path with fallback
```

### CodeqlDb::Database::Manager

#### Methods

```ruby
manager.create(source_path, database_path, options = {})
manager.list_files(database_path, options = {})
manager.delete(database_path)
manager.exists?(database_path)
manager.info(database_path)
```

### CodeqlDb::Statistics::Analyzer

#### Methods

```ruby
analyzer.analyze(database_path, options = {})
analyzer.calculate_lines_of_code(file_paths)
```

### CodeqlDb::CLI::Wrapper

#### Methods

```ruby
wrapper.create_database(source_path, database_path, options = {})
wrapper.list_database_files(database_path)
wrapper.database_exists?(database_path)
wrapper.run_query(database_path, query_path, output_format = "csv")
wrapper.version
```

## Contributing

We welcome contributions to CodeQL DB! Here's how you can help:

### Development Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/codeql_db.git`
3. Install dependencies: `bundle install`
4. Install CodeQL CLI (see installation instructions above)
5. Run tests: `bundle exec rspec`

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/codeql_db/database/manager_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Code Style

We use RuboCop for code style enforcement:

```bash
# Check style
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a
```

### Submitting Changes

1. Create a feature branch: `git checkout -b feature/your-feature-name`
2. Make your changes
3. Add tests for new functionality
4. Ensure all tests pass: `bundle exec rspec`
5. Check code style: `bundle exec rubocop`
6. Commit your changes: `git commit -am 'Add some feature'`
7. Push to the branch: `git push origin feature/your-feature-name`
8. Create a Pull Request

### Reporting Issues

Please use the GitHub issue tracker to report bugs or request features. Include:

- Ruby version
- CodeQL CLI version
- Operating system
- Steps to reproduce the issue
- Expected vs actual behavior

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Acknowledgments

- GitHub for creating and maintaining CodeQL
- The Ruby community for inspiration and best practices
- All contributors who help improve this gem

---

**CodeQL DB** - Making CodeQL accessible to the Ruby community, one database at a time.