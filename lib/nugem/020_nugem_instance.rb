require 'erb'
require 'fileutils'
require 'find'
require 'pathname'
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
      @force       = options[:force] # TODO: delete this variable?
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
      directory exclude_pattern: %r{common/gem_scaffold/spec/.*},
                path_fragment:   'common/gem_scaffold'
      directory(path_fragment: 'common/executable_scaffold') if @options[:executable]
      template 'common/LICENCE.txt.tt', "#{@out_dir}/LICENCE.txt"
    end

    # Copy a directory structure to a destination with customizable options.
    # Somewhat compatible with Thor's directory method.
    #
    # @param path_fragment [String] Source directory path to copy from, relative to @options[:source_root]
    # @param destination [String] Target directory path to copy to.
    #        If a relative path is provided, it is interpreted as being relative to @options[:out_dir].
    #        Further, if @options[:out_dir] is nil, the current directory when this method is executed determines
    #        the resolution values of relative paths.
    # @param options [Hash] only supports :exclude_pattern, which must contain a regular expression;
    #                                     it excludes specified files/directories from copying.
    def directory(path_fragment:, destination: @out_dir || Dir.pwd, **options)
      unless path_fragment
        puts 'Error: Nugem.directory called without a path_fragment'.red
        exit 2
      end

      exclude_pattern = options[:exclude_pattern]

      source_path_fq = File.expand_path path_fragment, @options[:source_root]
      unless Dir.exist? source_path_fq
        msg = if File.exist? source_path_fq
                "Error: #{source_path_fq} is not a directory."
              else
                "Error: directory #{source_path_fq} does not exist."
              end
        puts msg.red
        return
      end

      dest_path_interpolated_fq = File.expand_path interpolate_percent_methods destination
      FileUtils.mkdir_p dest_path_interpolated_fq if Dir.exist?(source_path_fq)
      directory_processing dest_path_interpolated_fq: dest_path_interpolated_fq,
                           exclude_pattern:           exclude_pattern,
                           path_fragment:             path_fragment,
                           source_path_fq:            source_path_fq
    end

    # Internal method to iterate through directory entries.
    #
    # @param dest_path_interpolated_fq [String] Fully qualified destination directory path
    # @param exclude_pattern [Regexp, nil] Optional regular expression to exclude files/directories
    # @param path_fragment [String] Relative directory to write to
    # @param source_path_fq [String] Fully qualified source directory path
    # @return [void]
    def directory_processing(dest_path_interpolated_fq:, path_fragment:, source_path_fq:, exclude_pattern: nil)
      unless dest_path_interpolated_fq
        puts "Error: Nugem.directory_processing called without a dest_path_interpolated_fq; path_fragment=#{path_fragment}".red
        exit 2
      end
      unless path_fragment
        puts "Error: Nugem.directory_processing called without a path_fragment; source_path_fq=#{source_path_fq}".red
        exit 2
      end
      unless source_path_fq
        puts "Error: Nugem.directory_processing called without a source_path_fq; path_fragment=#{path_fragment}".red
        exit 2
      end

      # Iterate through all files and directories in source_path_fq
      Dir.glob(File.join(source_path_fq, '**', '*'), File::FNM_DOTMATCH).each do |entry|
        puts "  Examining #{entry}".green
        next if entry.end_with? '.', '..'

        relative_path = entry.sub %r{^#{Regexp.escape(source_path_fq)}/?}, ''
        next if relative_path.empty?
        next if exclude_pattern && relative_path.match?(exclude_pattern)

        source_entry_path_fq = File.join source_path_fq, relative_path
        next if Dir.exist? source_entry_path_fq

        dest_entry_path_fq = File.join dest_path_interpolated_fq, relative_path

        directory_entry dest_path_fq:            dest_entry_path_fq,
                        source_path_fq:          source_entry_path_fq,
                        this_is_a_template_file: path_fragment.end_with?('.tt')
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
    # Copy file (and expand its contents if it is a template) with appropriate mode handling
    #
    # @param dest_path_fq [String] Fully qualified destination path
    # @param source_path_fq [String] Fully qualified source path
    # @param this_is_a_template_file [Boolean] True if the file is a template
    # @return [void]
    def directory_entry(dest_path_fq:, source_path_fq:, this_is_a_template_file:)
      if File.exist?(dest_path_fq) && !@force
        puts "Not overwriting #{dest_path_fq} because --force was not specified."
        return
      end

      puts "Creating #{dest_path_fq}." unless Dir.exist?(dest_path_fq)
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

    def initialize_repository
      puts "Initializing repository for #{@options[:gem_name]} at #{@repository.host}.".green
      @repository.create_local_git_repository if %i[github gitlab bitbucket].include?(@repository.host)
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

    # Counts the number of 'TODO' strings in the given file within the output directory
    def todos_count(filename)
      filename_fq = "#{@options[:out_dir]}/#{filename}"

      unless File.exist?(filename_fq)
        puts "Error: #{filename_fq} does not exist, there are no TODOs to count.".red
        return 0
      end

      content = File.exist?(filename_fq) ? File.read(filename_fq) : ''
      content.scan('TODO').length
    end

    # Shows how many TODOs are in the gemspec and README files
    # @return [String] Multiline string indicating the number of TODOs found
    def todos_report
      gem_name = @options[:gem_name]
      gemspec_todos = todos_count "#{gem_name}.gemspec"
      readme_todos = todos_count 'README.md'
      if readme_todos.zero? && gemspec_todos.zero?
        puts "There are no TODOs. You can run 'bundle' from within your new gem project now.".blue
        return
      end

      msg = 'Please complete'
      msg << " the #{gemspec_todos} TODOs in #{gem_name}.gemspec" if gemspec_todos.positive?
      msg << ' and' if gemspec_todos.positive? && readme_todos.positive?
      msg << " the #{readme_todos} TODOs in README.md." if readme_todos.positive?
      msg
    end
  end
end
