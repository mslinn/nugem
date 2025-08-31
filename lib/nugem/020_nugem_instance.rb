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
      @gem_name = options[:gem_name]
      @options = options
      @class_name = ::Nugem.camel_case(@gem_name)
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
      out_dir = @options[:out_dir]
      puts "Creating a scaffold for a new Ruby gem named #{@gem_name} in #{out_dir}.".green
      directory 'common/gem_scaffold', out_dir, force: true, mode: :preserve, exclude_pattern: 'spec/*'
      directory 'common/executable_scaffold', out_dir, force: true, mode: :preserve if @options[:executable]
      template 'common/LICENCE.txt.tt', "#{out_dir}/LICENCE.txt", force: true if @repository.public?
    end

    # Copies a directory structure to a destination with customizable options
    # Compatible with Thor's directory method.
    #
    # @param path_fragment [String] Source directory path to copy from, relative to @options[:source_root]
    # @param destination [String] Target directory path to copy to
    # @param force [Boolean] Overwrite existing files if true (default: true)
    # @param mode [Symbol, Integer] File permission handling: :preserve to keep source permissions, or an integer for specific permissions (default: :preserve)
    # @param exclude_pattern [Regexp, nil] Regular expression to exclude files/directories from copying (default: nil)
    def directory(path_fragment, destination, force: true, mode: :preserve, exclude_pattern: nil)
      source_path = File.expand_path @options[:source_root], path_fragment
      dest_path = File.expand_path destination
      return unless File.directory? source_path

      FileUtils.mkdir_p dest_path

      # Iterate through all files and directories in source
      Dir.glob(File.join(source_path, '**', '*'), File::FNM_DOTMATCH).each do |source|
        next if source.end_with? '.', '..'

        relative_path = source.sub %r{^#{Regexp.escape(source_path)}/?}, ''
        next if relative_path.empty?
        next if exclude_pattern && relative_path.match?(exclude_pattern)

        directory_entry dest_path, relative_path, force: force, mode: mode
      rescue StandardError => e
        puts "Error processing #{source}: #{e.message}".red
        next
      end
    end

    # Process a template directory entry (file or directory)
    # @param relative_path [String] Path relative to the source root
    # @param force [Boolean] Whether to overwrite existing files (default: true)
    # @param mode [Symbol, Integer] File permission handling: :preserve to keep source permissions,
    #   or an integer for specific permissions (default: :preserve)
    def directory_entry(dest_path, relative_path, force: true, mode: :preserve)
      dest_file_temp = File.join dest_path, relative_path
      dest_path = interpolate_percent_methods(dest_file_temp, [self, @repository, ::Nugem])
      this_is_a_template_file = dest_path.end_with? '.tt'
      dest_path.delete_suffix! '.tt'

      source_path = File.expand_path File.join @options[:source_root], relative_path
      if File.directory?(source_path)
        FileUtils.mkdir_p dest_path
      else # Copy file with appropriate mode handling
        if File.exist?(dest_path) && !force
          puts "Not overwriting #{dest_path} because --force was not specified."
          return
        end

        FileUtils.mkdir_p File.dirname(dest_path)
        if this_is_a_template_file # read and process ERB template
          erb = ERB.new(File.read(source_path), trim_mode: '-')
          expanded_content = erb.result(binding) # FIXME: does this work?
          File.write dest_path, expanded_content
        else
          FileUtils.cp(source_path, dest_path)
        end

        if mode == :preserve # Preserve original file permissions
          FileUtils.chmod File.stat(source_path).mode, dest_path
        elsif mode.is_a?(Integer) # Set specific mode if provided
          FileUtils.chmod mode, dest_path
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

    # Replace substrings of the form %methodname% in a string
    # by calling the first object in an array that responds to that method.
    #
    # Example:
    #   class Person
    #     def name; "Alice"; end
    #   end
    #
    #   class Info
    #     def age; 30; end
    #   end
    #
    #   objs = [Person.new, Info.new]
    #   template = "Hello %name%, you are %age% years old."
    #   interpolate_percent_methods(template, objs)
    #   => "Hello Alice, you are 30 years old."
    #
    def interpolate_percent_methods(str, objs)
      str.gsub(/%(\w+)%/) do
        method_name = Regexp.last_match(1) # Extract text between %...%

        # Find the first object in the array that responds to this method
        obj = objs.find { |o| o.respond_to?(method_name) }

        if obj
          obj.send(method_name)              # Call it and substitute the result
        else
          puts "Warning: No object found responding to method '#{method_name}'".red
          "%#{method_name}%"                 # Leave unchanged if no match found
        end
      end
    end

    # Colorize text if the 'colorize' gem is available; otherwise return plain text
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
    # def copy_directory_recursively(src, dest, force: true, preserve_mode: true, exclude_pattern: nil)
    #   raise ArgumentError, "Source directory '#{src}' does not exist" unless Dir.exist?(src)

    #   # Normalize paths
    #   src = File.expand_path(src)
    #   dest = File.expand_path(dest)

    #   Find.find(src) do |path|
    #     # Compute destination path
    #     rel_path = path.sub(%r{^#{Regexp.escape(src)}/?}, '')
    #     next if rel_path.empty?

    #     # Skip excluded files/directories
    #     if exclude_pattern && rel_path.match?(exclude_pattern)
    #       puts "  Skipping excluded path: #{rel_path}"
    #       Find.prune if File.directory?(path)
    #       next
    #     end

    #     target = File.join(dest, rel_path)

    #     if File.directory?(path)
    #       FileUtils.mkdir_p(target)
    #       FileUtils.chmod(File.stat(path).mode, target) if preserve_mode
    #     elsif File.file?(path)
    #       if !File.exist?(target) || force
    #         FileUtils.mkdir_p(File.dirname(target))
    #         FileUtils.cp(path, target, preserve: preserve_mode)
    #       end
    #     elsif File.symlink?(path)
    #       link_target = File.readlink(path)
    #       FileUtils.ln_s(link_target, target, force: force)
    #     end
    #   rescue Errno::ENOENT => e
    #     puts "Source directory not found: #{e.message}; copy aborted".red
    #     break
    #   rescue Errno::EACCES => e
    #     puts "Permission denied: #{e.message}; file or directory".red
    #     # No break here, continue to next file
    #   rescue StandardError => e
    #     puts "Error copying files: #{e.message}; copy aborted".red
    #     break
    #   end
    # end

    # Processes an ERB template and generates a file at the specified destination
    # Compatible with Thor's template method.
    #
    # @param source [String] Path to the ERB template file, relative to the source root
    # @param destination [String] Target path for the generated file
    # @param force [Boolean] Overwrite existing file if true (default: true)
    # @param context [Binding, nil] Binding context for ERB evaluation (default: nil, uses current binding)
    # @param mode [Symbol, Integer] File permission handling: :preserve to keep source permissions,
    # or an integer for specific permissions (default: :preserve)
    def template(source, destination, force: true, context: nil, mode: :preserve)
      source_path = File.expand_path(source)
      dest_path = File.expand_path(destination)

      unless File.exist?(source_path)
        puts "Error: Template file not found: #{source_path}".red
        exit 2
      end

      # Read and process ERB template
      template_content = File.read source_path
      erb = ERB.new(template_content, trim_mode: '-')
      result = erb.result(context || binding)

      FileUtils.mkdir_p File.dirname(dest_path) # Create parent directories for destination

      # Check if destination exists and handle force option
      if File.exist?(dest_path) && !force
        puts "Skipping #{dest_path} because it already exists"
        return
      end

      File.write dest_path, result # Write processed content to destination

      if mode == :preserve # Preserve original file permissions
        FileUtils.chmod File.stat(source_path).mode, dest_path
      elsif mode.is_a?(Integer)
        FileUtils.chmod(mode, dest_path) # Set specific mode if provided
      end
    end
  end
end
