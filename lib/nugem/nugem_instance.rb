require 'fileutils'
require 'find'
module Nugem
  # Created by vscode to avoid name conflicts with Nugem::Nugem
  class Nugem
    attr_reader :gem_name, :options, :dir, :class_name, :module_name, :repository

    DEFAULT_OPTIONS = {
      out_dir:     "#{Dir.home}/nugem_generated",
      host:        :github,
      private:     false,
      executables: false,
    }.freeze

    # Initializes a new Nugem instance with the given gem name and options.
    #
    # @param gem_name [String] The name of the gem.
    # @param options [Hash] Options for the gem scaffold, including host, private, and out_dir.
    #
    # @return [Nugem] A new instance of Nugem.
    #
    # @example
    #   nugem = Nugem.new('my_gem', host: 'github', private: false, out_dir: 'output')
    def initialize(gem_name, options = DEFAULT_OPTIONS)
      @gem_name = gem_name
      @options = options
      @class_name = ::Nugem.camel_case(@gem_name)
      @module_name = "#{@class_name}Module"
      @repository = ::Nugem::Repository.new(
        host:    @options[:host],
        name:    @gem_name,
        private: @options[:private],
        user:    git_repository_user_name(@options[:host])
      )
    end

    def create_scaffold
      puts "Creating a scaffold for a new Ruby gem named #{@gem_name} in #{@options[:out_dir]}.".green
      directory 'common/gem_scaffold',        @options[:out_dir], force: true, mode: :preserve, exclude_pattern: 'spec/*'
      directory 'common/executable_scaffold', @options[:out_dir], force: true, mode: :preserve if @options[:executables]
      template 'common/LICENCE.txt', "#{@options[:out_dir]}/LICENCE.txt", force: true if @repository.public?
    end

    def initialize_repository
      puts set_color("Initializing repository for #{@gem_name} at #{@repository.host}.", :green)
      @repository.create if %i[github gitlab bitbucket].include?(@repository.host)
      @repository.push_to_remote(@options[:out_dir]) if @repository.public?
    end

    def git_repository_user_name(host)
      case host
      when :bitbucket | :gitlab | :github
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

    # Copy files from the source directory to the destination directory,
    # applying any specified options such as force, mode, or exclude patterns.
    #
    # @param source [String] The source directory to copy files from.
    # @param destination [String] The destination directory to copy files to.
    # @param options [Hash] Options for copying files, such as :force, :mode, and :exclude_pattern.
    #
    # @return [void]
    # @example
    #   directory('source_dir', 'destination_dir', force: true, mode: :preserve, exclude_pattern: /exclude_this/)
    #
    # @see FileUtils.cp for file copying options
    # @see Jekyll::Site for site processing options
    def copy_directory_recursively(src, dest, force: true, preserve_mode: true, exclude_pattern: nil)
      raise ArgumentError, "Source directory '#{src}' does not exist" unless Dir.exist?(src)

      # Normalize paths
      src = File.expand_path(src)
      dest = File.expand_path(dest)

      Find.find(src) do |path|
        # Compute destination path
        rel_path = path.sub(%r{^#{Regexp.escape(src)}/?}, '')
        next if rel_path.empty?

        # Skip excluded files/directories
        if exclude_pattern && rel_path.match?(exclude_pattern)
          puts "  Skipping excluded path: #{rel_path}"
          Find.prune if File.directory?(path)
          next
        end

        target = File.join(dest, rel_path)

        if File.directory?(path)
          FileUtils.mkdir_p(target)
          FileUtils.chmod(File.stat(path).mode, target) if preserve_mode
        elsif File.file?(path)
          if !File.exist?(target) || force
            FileUtils.mkdir_p(File.dirname(target))
            FileUtils.cp(path, target, preserve: preserve_mode)
          end
        elsif File.symlink?(path)
          link_target = File.readlink(path)
          FileUtils.ln_s(link_target, target, force: force)
        end
      rescue Errno::ENOENT => e
        puts "Source directory not found: #{e.message}; copy aborted".red
        break
      rescue Errno::EACCES => e
        puts "Permission denied: #{e.message}; file or directory".red
        # No break here, continue to next file
      rescue StandardError => e
        puts "Error copying files: #{e.message}; copy aborted".red
        break
      end
    end
  end
end
