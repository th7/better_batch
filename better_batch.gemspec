# frozen_string_literal: true

require_relative 'lib/better_batch/version'

Gem::Specification.new do |spec|
  spec.name = 'better_batch'
  spec.version = BetterBatch::VERSION
  spec.authors = ['Tyler Hartland']
  spec.email = ['tylerhartland7@gmail.com']

  spec.summary = 'A simple SQL query builder for better batch operations.'
  spec.homepage = 'https://github.com/th7/better_batch'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/th7/better_batch'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'anbt-sql-formatter', '~> 0.1'
end
