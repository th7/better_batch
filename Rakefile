# frozen_string_literal: true

require 'English'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]

module Tasks
  BUILD_FILENAME = 'better_batch.gem'

  class << self
    include Rake::DSL

    def install
      install_release_if
    end

    private

    def install_release_if # rubocop:disable Metrics/MethodLength
      namespace :release do
        desc 'release if current version is later than last published version'
        task if: :default do
          assert_correct_branch!
          if current_version > published_version
            assert_ci!
            # from bundler, asserts working directory is clean
            Rake::Task['release'].invoke
          end
          assert_version_sane!
        end
      end
    end

    def published_version
      @published_version ||= build_published_version
    end

    def build_published_version
      raw = shr('gem search --remote --exact better_batch')
      Gem::Version.new(raw.split('(').last.sub(')', ''))
    end

    def current_version
      @current_version ||= Gem::Version.new(BetterBatch::VERSION)
    end

    def assert_version_sane!
      return unless current_version < published_version

      raise "BetterBatch::VERSION (#{current_version}) " \
            "is less than the current published (#{published_version}). " \
            'Was it edited incorrectly?'
    end

    def current_branch
      @current_branch ||= shr('git rev-parse --abbrev-ref HEAD').chomp
    end

    def default_branch
      @default_branch ||= shr('git remote show origin').match(/HEAD branch: (\S+)$/)[1]
    end

    def assert_correct_branch!
      return unless current_branch != default_branch

      raise "On branch (#{current_branch}) instead of default #{default_branch}."
    end

    def assert_ci!
      raise 'Not in CI.' unless ENV['CI'] == 'true'
    end

    def shr(cmd)
      puts cmd
      result = `#{cmd}`
      raise cmd unless $CHILD_STATUS == 0

      result
    end
  end
end

Tasks.install
