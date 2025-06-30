# frozen_string_literal: true

require_relative "lib/ruby_codeql_db/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_codeql_db"
  spec.version = RubyCodeqlDb::VERSION
  spec.authors = ["RubyCodeqlDb Team"]
  spec.email = ["laquereric@gmail.com"]

  spec.summary = "A comprehensive Ruby gem for CodeQL database management and analysis"
  spec.description = "RubyCodeqlDb provides a complete solution for creating, managing, and analyzing CodeQL databases in Ruby applications and Rails projects. It includes rake tasks for database operations, file analysis, and code statistics generation."
  spec.homepage = "https://github.com/example/ruby-codeql-db"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/example/ruby-codeql-db"
  spec.metadata["changelog_uri"] = "https://github.com/example/ruby-codeql-db/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "rake", "~> 13.0"
  spec.add_dependency "thor", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
