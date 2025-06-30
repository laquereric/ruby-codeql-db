# frozen_string_literal: true

require "bundler/setup"
require "ruby_codeql_db"
require "tempfile"
require "tmpdir"
require "fileutils"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Create temporary directories for testing
  config.before(:each) do
    @temp_dir = Dir.mktmpdir("ruby_codeql_db_test")
    @original_dir = Dir.pwd
  end

  config.after(:each) do
    Dir.chdir(@original_dir) if @original_dir
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  # Helper methods
  config.include Module.new {
    def temp_dir
      @temp_dir
    end

    def create_test_ruby_file(path, content = nil)
      content ||= <<~RUBY
        # Test Ruby file
        class TestClass
          def test_method
            puts "Hello, World!"
          end
        end
      RUBY

      full_path = File.join(temp_dir, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
      full_path
    end

    def create_test_gemfile(path = "Gemfile", content = nil)
      content ||= <<~GEMFILE
        source "https://rubygems.org"
        
        gem "rails", "~> 7.0"
        gem "sqlite3", "~> 1.4"
        gem "puma", "~> 5.0"
        
        group :development, :test do
          gem "rspec-rails"
          gem "factory_bot_rails"
        end
      GEMFILE

      full_path = File.join(temp_dir, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
      full_path
    end

    def create_test_gemspec(name = "test_gem", content = nil)
      content ||= <<~GEMSPEC
        Gem::Specification.new do |spec|
          spec.name = "#{name}"
          spec.version = "0.1.0"
          spec.authors = ["Test Author"]
          spec.email = ["test@example.com"]
          
          spec.summary = "Test gem"
          spec.description = "A test gem for RubyCodeqlDb testing"
          spec.homepage = "https://example.com"
          spec.license = "MIT"
          
          spec.files = Dir["lib/**/*"]
          spec.require_paths = ["lib"]
          
          spec.add_dependency "rails", "~> 7.0"
          spec.add_development_dependency "rspec", "~> 3.0"
        end
      GEMSPEC

      full_path = File.join(temp_dir, "#{name}.gemspec")
      File.write(full_path, content)
      full_path
    end

    def create_test_project_structure
      # Create a typical Ruby project structure
      create_test_ruby_file("lib/test_gem.rb", <<~RUBY)
        # Main library file
        require_relative "test_gem/version"
        require_relative "test_gem/configuration"
        require_relative "test_gem/manager"

        module TestGem
          class Error < StandardError; end

          def self.configure
            yield(configuration)
          end

          def self.configuration
            @configuration ||= Configuration.new
          end
        end
      RUBY

      create_test_ruby_file("lib/test_gem/version.rb", <<~RUBY)
        module TestGem
          VERSION = "0.1.0"
        end
      RUBY

      create_test_ruby_file("lib/test_gem/configuration.rb", <<~RUBY)
        module TestGem
          class Configuration
            attr_accessor :verbose, :timeout

            def initialize
              @verbose = false
              @timeout = 30
            end
          end
        end
      RUBY

      create_test_ruby_file("lib/test_gem/manager.rb", <<~RUBY)
        module TestGem
          class Manager
            def initialize(config)
              @config = config
            end

            def process
              puts "Processing..." if @config.verbose
              # Complex method with multiple branches
              if @config.timeout > 60
                handle_long_timeout
              elsif @config.timeout > 30
                handle_medium_timeout
              else
                handle_short_timeout
              end
            end

            private

            def handle_long_timeout
              # Nested complexity
              (1..10).each do |num|
                if num.even?
                  puts "Even: " + num.to_s
                else
                  puts "Odd: " + num.to_s
                end
              end
            end

            def handle_medium_timeout
              puts "Medium timeout"
            end

            def handle_short_timeout
              puts "Short timeout"
            end
          end
        end
      RUBY

      create_test_ruby_file("spec/test_gem_spec.rb", <<~RUBY)
        require "spec_helper"

        RSpec.describe TestGem do
          it "has a version number" do
            expect(TestGem::VERSION).not_to be nil
          end

          it "can be configured" do
            TestGem.configure do |config|
              config.verbose = true
            end
            expect(TestGem.configuration.verbose).to be true
          end
        end
      RUBY

      create_test_gemfile
      create_test_gemspec("test_gem")

      # Create some additional files for testing
      create_test_ruby_file("app/models/user.rb", <<~RUBY)
        class User
          attr_accessor :name, :email

          def initialize(name, email)
            @name = name
            @email = email
          end

          def valid?
            !name.nil? && !email.nil? && email.include?("@")
          end
        end
      RUBY

      create_test_ruby_file("app/controllers/users_controller.rb", <<~RUBY)
        class UsersController
          def index
            @users = User.all
          end

          def show
            @user = User.find(params[:id])
          end

          def create
            @user = User.new(user_params)
            if @user.save
              redirect_to @user
            else
              render :new
            end
          end

          private

          def user_params
            params.require(:user).permit(:name, :email)
          end
        end
      RUBY
    end

    def mock_codeql_cli_available
      allow_any_instance_of(RubyCodeqlDb::Configuration).to receive(:cli_available?).and_return(true)
      allow_any_instance_of(RubyCodeqlDb::CLI::Wrapper).to receive(:version).and_return("2.15.0")
    end

    def mock_codeql_cli_unavailable
      allow_any_instance_of(RubyCodeqlDb::Configuration).to receive(:cli_available?).and_return(false)
    end
  }
end

