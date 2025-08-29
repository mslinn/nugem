require 'erb'
require 'fileutils'
require 'find'
require 'rugged'

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
    #   nugem = Nugem.new({
    #     gem_name: 'my_gem',
    #     gem_type: 'ruby',
    #     host: 'github',
    #     private: false,
    #     out_dir: '~/output'
    #   })
    def initialize(options = DEFAULT_OPTIONS)
      @options = options
      @class_name = ::Nugem.camel_case(options[:gem_name])
      @module_name = "#{@class_name}Module"
      repository_user_name = git_repository_user_name(@options[:host])
      @repository = ::Nugem::Repository.new(
        host:    @options[:host],
        name:    @options[:gem_name],
        private: @options[:private],
        user:    repository_user_name
      )
    end

    def create_scaffold
      puts "Creating a scaffold for a new Ruby gem named #{@options[:gem_name]} in #{@options[:out_dir]}.".green
      directory 'common/gem_scaffold', @options[:out_dir], force: true, mode: :preserve,
                exclude_pattern: 'spec/*'
      if @options[:executable]
        directory 'common/executable_scaffold', @options[:out_dir], force: true,
                                                                    mode:  :preserve
      end
      template 'common/LICENCE.txt', "#{@options[:out_dir]}/LICENCE.txt", force: true if @repository.public?
    end

    # Copies a directory structure to a destination with customizable options
    # Compatible with Thor's directory method.
    #
    # @param path_fragment [String] Source directory path to copy from
    # @param destination [String] Target directory path to copy to
    # @param force [Boolean] Overwrite existing files if true (default: true)
    # @param mode [Symbol, Integer] File permission handling: :preserve to keep source permissions, or an integer for specific permissions (default: :preserve)
    # @param exclude_pattern [Regexp, nil] Regular expression to exclude files/directories from copying (default: nil)
    def directory(path_fragment, destination, force: true, mode: :preserve, exclude_pattern: nil)
      # Resolve source and destination paths
      source_path = File.expand_path(path_fragment)
      dest_path = File.expand_path(destination)

      # Check if source directory exists
      return unless File.directory?(source_path)

      # Create destination directory if it doesn't exist
      FileUtils.mkdir_p(dest_path) unless File.exist?(dest_path)

      # Iterate through all files and directories in source
      Dir.glob(File.join(source_path, '**', '*'), File::FNM_DOTMATCH).each do |source|
        # Skip . and .. directories
        next if source.end_with?('.', '..')

        # Calculate relative path and destination file path
        relative_path = source.sub(%r{^#{Regexp.escape(source_path)}/?}, '')
        next if relative_path.empty?

        # Skip if file matches exclude_pattern
        next if exclude_pattern && relative_path.match?(exclude_pattern)

        dest_file = File.join(dest_path, relative_path)

        if File.directory?(source)
          # Create directory in destination
          FileUtils.mkdir_p(dest_file) unless File.exist?(dest_file)
        else
          # Copy file with appropriate mode handling
          if File.exist?(dest_file) && !force
            puts "Skipping #{dest_file} (already exists)"
            next
          end

          FileUtils.mkdir_p(File.dirname(dest_file)) unless File.exist?(File.dirname(dest_file))

          # Copy file and handle mode
          FileUtils.cp(source, dest_file)

          if mode == :preserve
            # Preserve original file permissions
            FileUtils.chmod(File.stat(source).mode, dest_file)
          elsif mode.is_a?(Integer)
            # Set specific mode if provided
            FileUtils.chmod(mode, dest_file)
          end
        end
      end
    end

    def initialize_repository
      puts set_color("Initializing repository for #{@options[:gem_name]} at #{@repository.host}.", :green)
      @repository.create_local_git_repository if %i[github gitlab bitbucket].include?(@repository.host)
      @repository.push_to_remote(@options[:out_dir]) if @repository.public?
    end

    def git_repository_user_name(host)
      case host
      when 'bitbucket', 'gitlab', 'github'
        Rugged::Config.global['user.name']
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

    # TODO: figure out what I was thinking here
    def template_what_huh(source, destination, options = {})
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

    # Processes an ERB template and generates a file at the specified destination
    # Compatible with Thor's template method.
    #
    # @param source [String] Path to the ERB template file
    # @param destination [String] Target path for the generated file
    # @param force [Boolean] Overwrite existing file if true (default: true)
    # @param context [Binding, nil] Binding context for ERB evaluation (default: nil, uses current binding)
    # @param mode [Symbol, Integer] File permission handling: :preserve to keep source permissions,
    # or an integer for specific permissions (default: :preserve)
    def template(source, destination, force: true, context: nil, mode: :preserve)
      # Resolve source and destination paths
      source_path = File.expand_path(source)
      dest_path = File.expand_path(destination)

      # Check if source template exists
      raise "Template file not found: #{source_path}" unless File.exist?(source_path)

      # Read and process ERB template
      template_content = File.read(source_path)
      erb = ERB.new(template_content, trim_mode: '-')
      result = erb.result(context || binding)

      # Create parent directories for destination
      FileUtils.mkdir_p(File.dirname(dest_path)) unless File.exist?(File.dirname(dest_path))

      # Check if destination exists and handle force option
      if File.exist?(dest_path) && !force
        puts "Skipping #{dest_path} (already exists)"
        return
      end

      # Write processed content to destination
      File.write(dest_path, result)

      # Handle file permissions
      if mode == :preserve
        # Preserve original file permissions
        FileUtils.chmod(File.stat(source_path).mode, dest_path)
      elsif mode.is_a?(Integer)
        # Set specific mode if provided
        FileUtils.chmod(mode, dest_path)
      end
    end
  end
end
