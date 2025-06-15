require 'fileutils'
require 'rugged'
require_relative 'git'
require_relative 'cli/cli_gem'

# Nugem::Cli is a Thor class that is invoked when a user runs a nugem executable.
# This file defines the common aspects of the Thor class.
# The cli/ directory contains class extensions specific to each Thor subcommand.
module Nugem
  class Cli
    # These declarations make the class instance variable values available as an accessor,
    # which is necessary to name template files that are named '%variable_name%.extension'.
    # See https://www.rubydoc.info/gems/thor/Thor/Actions#directory-instance_method
    attr_reader :block_name, :filter_name, :generator_name, :tag_name, :test_framework

    package_name 'Nugem'

    check_unknown_options!

    class_option :out_dir, type: :string, default: 'generated',
                 desc: 'Output directory for the gem.', aliases: :o

    class_option :executable, type: :boolean, default: false,
                 desc: 'Include an executable for the gem.', aliases: :e

    class_option :host, type: :string, default: 'github',
                 enum: %w[bitbucket github], desc: 'Repository host.', aliases: :h

    class_option :private, type: :boolean, default: false,
                 desc: 'Publish the gem on a private repository.'

    class_option :quiet, type: :boolean, default: true,
                 desc: 'Suppress detailed messages.', group: :runtime, aliases: :q

    class_option :todos, type: :boolean, default: true,
                 desc: 'Generate TODO: messages in generated code.', group: :runtime, aliases: :t

    class_option :yes, type: :boolean, default: false,
                 desc: 'Answer yes to all questions.', aliases: :y

    # Surround gem_name with percent symbols when using the property to name files
    # within the template directory
    # For example: "generated/%gem_name%"
    attr_accessor :gem_name

    # Return a non-zero status code on error. See https://github.com/rails/thor/issues/244
    def self.exit_on_failure?
      true
    end

    # @return Path to the Thor generator templates
    def self.source_root
      File.expand_path '../../templates', __dir__
    end

    def self.test_option(default_value)
      method_option :test_framework, type: :string, default: default_value,
        enum: %w[minitest rspec],
        desc: "Use rspec or minitest for the test framework (default is #{default_value})."
    end

    def self.todo
      'TODO: ' if @todos
    end

    require_relative 'cli/cli_jekyll'

    no_tasks do # rubocop:disable Metrics/BlockLength
      def count_todos(filename)
        filename_fq = "#{Nugem.dest_root @out_dir, gem_name}/#{filename}"
        content = File.read filename_fq
        content.scan('TODO').length
      end

      def initialize_repository(gem_name)
        Dir.chdir Nugem.dest_root(@out_dir, gem_name) do
          # puts set_color("Working in #{Dir.pwd}", :green)
          run 'chmod +x bin/*'
          run 'chmod +x exe/*' if @executable
          create_local_git_repository
          FileUtils.rm_f 'Gemfile.lock'
          # puts set_color("Running 'bundle'", :green)
          # run 'bundle', abort_on_failure: false
          create_repo = @yes || yes?(set_color("Do you want to create a repository on #{@repository.host.camel_case} named #{gem_name}? (y/N)",
                                               :green))
          create_remote_git_repository @repository if create_repo
        end
        puts set_color("The #{gem_name} gem was successfully created.", :green)
        puts set_color('Remember to run bin/setup in the new gem directory', :green)
        report_todos gem_name
      end

      def report_todos(gem_name)
        gemspec_todos = count_todos "#{gem_name}.gemspec"
        readme_todos  = count_todos 'README.md'
        if readme_todos.zero? && gemspec_todos.zero?
          puts set_color("There are no TODOs. You can run 'bundle' from within your new gem project now.", :blue)
          return
        end

        msg = 'Please complete'
        msg << " the #{gemspec_todos} TODOs in #{gem_name}.gemspec" if gemspec_todos.positive?
        msg << ' and' if gemspec_todos.positive? && readme_todos.positive?
        msg << " the #{readme_todos} TODOs in README.md." if readme_todos.positive?
        puts set_color(msg, :yellow)
      end
    end
  end
end
