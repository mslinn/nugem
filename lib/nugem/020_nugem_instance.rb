require 'erb'
require 'fileutils'
require 'find'
require 'rugged'

module Nugem
  class Nugem
    attr_reader :gem_name, :options, :dir, :class_name, :module_name, :repository

    DEFAULT_OPTIONS = {
      out_dir:     "#{Dir.home}/nugem_generated",
      host:        :github,
      private:     false,
      executables: false,
    }.freeze

    # Initialize a new Nugem instance with the given gem name and options.
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
      @force       = options[:force]
      @out_dir     = options[:out_dir]
      repository_user_name = git_repository_user_name(@options[:host])
      @repository = ::Nugem::Repository.new(
        host:    @options[:host],
        name:    @options[:gem_name],
        private: @options[:private],
        user:    repository_user_name
      )
      @acb = ArbitraryContextBinding.new base_binding: binding, modules: [::Nugem], objects: [self]
    end

    def create_scaffold
      puts "create_scaffold: Creating a scaffold for a new Ruby gem named #{@gem_name} in #{@out_dir}.".green
      directory 'common/gem_scaffold', @out_dir, exclude_pattern: 'common/gem_scaffold/spec/.*'
      directory('common/executable_scaffold', @out_dir) if @options[:executable]
      template 'common/LICENCE.txt.tt', "#{@out_dir}/LICENCE.txt" if @repository.public?
    end

    # Copy a directory structure to a destination with customizable options.
    # Compatible with Thor's directory method.
    #
    # @param path_fragment [String] Source directory path to copy from, relative to @options[:source_root]
    # @param destination_fq [String] Target directory absolute path to copy to (normally starts with @options[:out_dir])
    # @param options [Hash] only supports :exclude_pattern, which must contain a regular expression;
    #                                     it excludes specified files/directories from copying
    def directory(path_fragment, destination_fq, **options)
      exclude_pattern = options[:exclude_pattern]

      source_path_fq = File.join File.expand_path(@options[:source_root]), path_fragment
      unless Dir.exist? source_path_fq
        msg = if File.exist? source_path_fq
                "Error: #{source_path_fq} is not a directory."
              else
                "Error: directory #{source_path_fq} does not exist."
              end
        puts msg.red
        return
      end

      dest_path_fq = interpolate_percent_methods File.expand_path destination_fq
      FileUtils.mkdir_p dest_path_fq if Dir.exist?(source_path_fq)

      # Iterate through all files and directories in source_path
      Dir.glob(File.join(source_path_fq, '**', '*'), File::FNM_DOTMATCH).each do |entry|
        next if entry.end_with? '.', '..'

        relative_path = entry.sub %r{^#{Regexp.escape(source_path)}/?}, ''
        next if relative_path.empty?
        next if exclude_pattern && relative_path.match?(exclude_pattern)

        directory_entry source_path_fq, dest_path_interpolated_fq, path_fragment.end_with?('.tt')
      rescue StandardError => e
        puts <<~END_MSG.red
          Error processing directory entry #{entry}:
            #{e.message}
            Directory processing of #{source_path_fq} terminated.
        END_MSG
        break
      end
    end

    # Process a template directory entry (file or directory).
    # @param relative_path [String] Path relative to the source root
    def directory_entry(source_path_fq, dest_path_fq, this_is_a_template_file)
      if File.directory?(source_path_fq)
        FileUtils.mkdir_p dest_path_fq
      else # Copy file (and expand its contents if it is a template) with appropriate mode handling
        if File.exist?(dest_path_fq) && !@force
          puts "Not overwriting #{dest_path_fq} because --force was not specified."
          return
        end

        FileUtils.mkdir_p File.dirname(dest_path_fq)
        if this_is_a_template_file # read and process ERB template
          begin
            expanded_content = @acb.render File.read source_path_fq
            puts "  Expanding template #{source_path_fq} to #{dest_path_fq}".green
            File.write dest_path_fq, expanded_content
            preserve_mode source_path_fq, dest_path_fq
          rescue NameError => e
            puts <<~END_MSG.red
              Error processing template #{source_path_fq}: method #{e.name} is not defined in the context where the ERB is evaluated.
            END_MSG
            nil
          end
        else
          puts "  Copying #{source_path_fq} to #{dest_path_fq}".green
          FileUtils.cp(source_path_fq, dest_path_fq) # Preserves file contents and permissions but not owner or group
        end
      end
    end

    def initialize_repository
      puts "Initializing repository for #{@options[:gem_name]} at #{@repository.host}.".green
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
    def interpolate_percent_methods(str)
      str.gsub(/%(\w+)%/) do
        method_name = Regexp.last_match(1) # Extract text between %...%
        @acb.render "<%= #{method_name} %>"
      rescue NameError
        puts "Warning: No object found responding to method '#{method_name}'".red
        "%#{method_name}%" # Leave unchanged if no match found
      end
    end

    def preserve_mode(source_path, dest_path)
      file_mode = File.stat(source_path).mode
      puts "  Setting #{source_path} to mode #{file_mode.to_s(8)}".green
      FileUtils.chmod file_mode, dest_path
    end

    # TODO: figure out what I was thinking here
    def template_what_huh(source, destination, options = {})
      require 'jekyll'
      site = Jekyll::Site.new(Jekyll.configuration({}))
      site.process
      FileUtils.cp(source, destination, options)
    end

    # Processes an ERB template and generates a file at the specified destination
    # Compatible with Thor's template method.
    #
    # @param source [String] Path to the ERB template file, relative to the source root
    # @param destination [String] Target path for the generated file
    # @param context [Binding, nil] Binding context for ERB evaluation (default: nil, uses current binding)
    # @param mode [Symbol, Integer] File permission handling: :preserve to keep source permissions,
    # or an integer for specific permissions (default: :preserve)
    def template(source, destination, context: nil, mode: :preserve)
      source_path = File.expand_path File.join @options[:source_root], source
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
      if File.exist?(dest_path) && !@force
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
