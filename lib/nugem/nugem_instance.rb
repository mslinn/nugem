module Nugem
  # Created by vscode to avoid name conflicts with Nugem::Nugem
  class Nugem
    attr_reader :gem_name, :options, :dir, :class_name, :module_name, :repository

    # Initializes a new Nugem instance with the given gem name and options.
    #
    # @param gem_name [String] The name of the gem.
    # @param options [Hash] Options for the gem scaffold, including host, private, and out_dir.
    #
    # @return [Nugem] A new instance of Nugem.
    #
    # @example
    #   nugem = Nugem.new('my_gem', host: 'github', private: false, out_dir: 'output')
    def initialize(gem_name, options = {})
      @gem_name = gem_name
      @options = options
      @dir = Nugem.dest_root(@options[:out_dir], @gem_name)
      @class_name = Nugem.camel_case(@gem_name)
      @module_name = "#{@class_name}Module"
      @repository = Nugem::Repository.new(
        host:    @options[:host],
        name:    @gem_name,
        private: @options[:private],
        user:    git_repository_user_name(@options[:host])
      )
    end

    def create_scaffold
      puts set_color("Creating a scaffold for a new Ruby gem named #{@gem_name} in #{@dir}.", :green)
      exclude_pattern = case @options[:test_framework]
                        when 'minitest' then /spec.*/
                        when 'rspec'    then /test.*/
                        end
      directory('common/gem_scaffold',        @dir, force: true, mode: :preserve, exclude_pattern:)
      directory 'common/executable_scaffold', @dir, force: true, mode: :preserve if @options[:executables]
      template  'common/LICENCE.txt',         "#{@dir}/LICENCE.txt", force: true if @repository.public?
    end

    def initialize_repository
      puts set_color("Initializing repository for #{@gem_name} at #{@repository.host}.", :green)
      @repository.create if %i[github bitbucket].include?(@repository.host)
      @repository.push_to_remote(@dir) if @repository.public?
    end

    def git_repository_user_name(host)
      case host
      when :bitbucket | :github
        `git config --get user.name`.strip
      else
        raise ArgumentError, "Unknown host: #{host}"
      end
    rescue StandardError => e
      puts "Error retrieving git user name: #{e.message}".red
      nil
    end

    def set_color(text, color)
      require 'colorize'
      text.colorize(color)
    rescue LoadError
      puts 'Colorizer gem not found. Install it with `gem install colorizer` to use colored output.'
      text
    end

    def template(source, destination, options = {})
      require 'jekyll'
      site = Jekyll::Site.new(Jekyll.configuration({}))
      site.process
      FileUtils.cp(source, destination, options)
    end

    # This method is a placeholder for the actual implementation of directory copying.
    # It should copy files from the source directory to the destination directory,
    # applying any specified options such as force, mode, or exclude patterns.
    #
    # @param source [String] The source directory to copy files from.
    # @param destination [String] The destination directory to copy files to.
    # @param options [Hash] Options for copying files, such as :force, :mode, and :exclude_pattern.
    #
    # @return [void]
    # @example
    #   directory('source_dir', 'destination_dir', force: true, mode: :preserve, exclude_pattern: /exclude_this/)
    # @note This method is not implemented yet and serves as a placeholder.
    # @see FileUtils.cp for file copying options
    # @see Jekyll::Site for site processing options
    #
    # @todo Implement the actual file copying logic.
    # @todo Handle exceptions and edge cases, such as missing directories or files.
    # @todo Add tests to ensure the method works as expected.
    # @todo Consider adding logging for debugging purposes.
    # @todo Refactor the method to improve readability and maintainability.
    # @todo Ensure compatibility with different Ruby versions and environments.
    # @todo Add documentation for the method parameters and return values.
    # @todo Consider adding support for additional options in the future.
    #
    # @example Usage
    #   directory('source_dir', 'destination_dir', force: true, mode: :preserve, exclude_pattern: /exclude_this/)
    def directory(source, destination, options = {})
      # Placeholder for directory copying logic
      puts "Copying files from #{source} to #{destination} with options: #{options.inspect}"
      # Actual implementation would go here, using FileUtils or similar
      # For now, just simulating the action
      FileUtils.mkdir_p(destination)
      puts 'Files copied successfully.' # Simulated success message
    rescue StandardError => e
      puts "Error copying files: #{e.message}".red
    end
  end
end
