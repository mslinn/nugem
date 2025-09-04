require 'erb'
require 'fileutils'
require 'find'
require 'pathname'
require 'rugged'

module Nugem
  class Nugem
    attr_reader :acb, :gem_name, :options, :dir, :class_name, :module_name, :repository

    DEFAULT_OPTIONS = {
      out_dir:     "#{Dir.home}/nugem_generated",
      host:        :github,
      private:     false,
      executables: [],
    }.freeze

    # Initialize a new Nugem instance with the given gem name and options.
    # Defines various globals, including @acb [ArbitraryContextBinding], which is used to resolve variable
    # references in ERB templates
    #
    # @param gem_name [String] The name of the gem.
    # @param options [Hash] Options for the gem scaffold, including host, private, and out_dir.
    #                if an environment variable called my_gems is defined, out_dir will default to $my_gems/gem_name,
    #                otherwise out_dir will default to ~/nugem_generated/gem_name.
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
      @options     = options
      @gem_name    = options[:gem_name]
      @force       = options[:force] # TODO: clarify what this variable actually does

      @class_name  = ::Nugem.camel_case(@gem_name)
      @module_name = "#{@class_name}Module"

      repository_user_name = git_repository_user_name(@options[:host])
      @repository = ::Nugem::Repository.new(
        host:    @options[:host],
        name:    @options[:gem_name],
        private: @options[:private],
        user:    repository_user_name
      )
      output_directory
      @acb = ArbitraryContextBinding.new base_binding: binding, modules: [::Nugem], objects: [self]
    end

    def create_scaffold
      puts "create_scaffold: Creating a scaffold for a new Ruby gem named #{@gem_name} in #{@out_dir}.".green
      directory exclude_pattern:   %r{common/gem_scaffold/spec/.*},
                src_path_fragment: 'common/gem_scaffold'
      directory(src_path_fragment: 'common/executable_scaffold') if @options[:executables].any?
      template 'common/LICENCE.txt.tt', "#{@out_dir}/LICENCE.txt"
    end

    # Copy a directory structure to a destination with customizable options.
    # Somewhat compatible with Thor's directory method.
    #
    # @param src_path_fragment [String] Source directory path to copy from, relative to @options[:source_root]
    # @param dest_root [String] Target directory path to copy to.
    #        If a relative path is provided, it is interpreted as being relative to @options[:out_dir].
    #        Further, if @options[:out_dir] is also nil, the current directory when this method is executed
    #        determines the resolution values of relative paths.
    # @param options [Hash] only supports :exclude_pattern, which must contain a regular expression;
    #                                     it excludes specified files/directories from copying.
    def directory(src_path_fragment:, dest_root: @out_dir || Dir.pwd, **options)
      unless src_path_fragment
        puts 'Error: Nugem.directory called without a src_path_fragment'.red
        exit 2
      end

      src_path_fq = File.expand_path src_path_fragment, @options[:source_root]
      unless Dir.exist? src_path_fq
        msg = if File.exist? src_path_fq
                "Error: #{src_path_fq} is not a directory."
              else
                "Error: directory #{src_path_fq} does not exist."
              end
        puts msg.red
        return
      end

      dest_root_interpolated = File.expand_path interpolate_percent_methods dest_root
      FileUtils.mkdir_p dest_root_interpolated if Dir.exist?(src_path_fq)
      directory_processing dest_root_interpolated: dest_root_interpolated,
                           exclude_pattern:        options[:exclude_pattern],
                           src_path_fragment:      src_path_fragment,
                           src_path_fq:            src_path_fq
    end

    # Internal method to iterate through directory entries.
    #
    # @param dest_root_interpolated [String] Fully qualified destination directory path
    # @param exclude_pattern [Regexp, String] Optional regular expression to exclude files/directories
    # @param src_path_fq [String] Fully qualified source directory path
    # @param src_path_fragment [String] Directory to write to, relative to src_path_fq
    # @return [void]
    def directory_processing(dest_root_interpolated:, src_path_fq:, src_path_fragment:, exclude_pattern: nil)
      if dest_root_interpolated.include?('%')
        puts "Error in directory_processing: Destination root #{dest_root_interpolated} contains a '%' character, which probably means interpolation failed.".red
        exit 5
      end
      unless dest_root_interpolated
        puts 'Error: Nugem.directory_processing called without dest_root_interpolated; ' \
             "src_path_fragment=#{src_path_fragment}".red
        exit 2
      end
      unless src_path_fragment
        puts "Error: Nugem.directory_processing called without src_path_fragment; src_path_fq=#{src_path_fq}".red
        exit 2
      end
      unless src_path_fq
        puts "Error: Nugem.directory_processing called without src_path_fq; src_path_fragment=#{src_path_fragment}".red
        exit 2
      end

      # Iterate through all files and directories in src_path_fq
      Dir.glob(File.join(src_path_fq, '**', '*'), File::FNM_DOTMATCH).each do |entry|
        # puts "  Examining #{entry.delete_prefix(src_path_fq + '/')}".green
        next if entry.end_with? '.', '..'

        src_path_interpolated_fq = interpolate_percent_methods src_path_fq
        if src_path_interpolated_fq.include?('%')
          puts "Error in directory_processing: Source path #{src_path_interpolated_fq} contains a '%' character, which probably means interpolation failed.".red
          exit 5
        end

        relative_path = entry.sub %r{^#{Regexp.escape(src_path_interpolated_fq)}/?}, ''
        next if relative_path.empty?

        if exclude_pattern
          exclude_regexp = case exclude_pattern
                           when String
                             Regexp.new(exclude_pattern)
                           when Regexp
                             exclude_pattern
                           else
                             puts "Error: exclude_pattern must be a String or Regexp, not #{exclude_pattern.class}".red
                             exit 3
                           end
          next if relative_path.match?(exclude_regexp)
        end
        relative_path_interpolated = interpolate_percent_methods(relative_path)

        source_entry_path_fq = File.join src_path_interpolated_fq, relative_path
        this_is_a_template_file = source_entry_path_fq.end_with?('.tt')
        next if Dir.exist? source_entry_path_fq

        dest_entry_path_fq = File.join(dest_root_interpolated, relative_path_interpolated).delete_suffix('.tt')

        directory_entry dest_path_fq:            dest_entry_path_fq,
                        src_path_fq:             source_entry_path_fq,
                        this_is_a_template_file: this_is_a_template_file
      rescue StandardError => e
        puts <<~END_MSG.red
          Error processing directory entry #{entry}:
            #{e.message}
            Directory processing of #{src_path_interpolated_fq} terminated.
        END_MSG
        break
      end
    end

    # Process a template directory entry (file or directory).
    # Copy file (and expand its contents if it is a template) with appropriate mode handling
    #
    # @param dest_path_fq [String] Fully qualified destination path, must not include % characters
    # @param src_path_fq [String] Fully qualified source path, can include % characters
    # @param this_is_a_template_file [Boolean] True if the file is a template
    # @return [void]
    def directory_entry(dest_path_fq:, src_path_fq:, this_is_a_template_file:)
      if dest_path_fq.include?('%')
        puts "Error in directory_entry: Destination path #{dest_path_fq} contains a '%' character, which probably means interpolation failed.".red
        exit 5
      end
      if dest_path_fq.end_with?('.tt')
        puts "Error in directory_entry: Destination path #{dest_path_fq} ends with '.tt', which means it was not recognized as a template.".red
        exit 5
      end
      if File.exist?(dest_path_fq) && !@force
        puts "Not overwriting #{dest_path_fq} because --force was not specified."
        return
      end

      puts "Creating #{dest_path_fq}." if File.directory?(src_path_fq) && !Dir.exist?(dest_path_fq)
      FileUtils.mkdir_p File.dirname(dest_path_fq)

      if this_is_a_template_file # read and process ERB template
        begin
          expanded_content = @acb.render File.read src_path_fq
          puts '  ' + <<~END_MSG.green # rubocop:disable Style/StringConcatenation
            Expanding template #{src_path_fq.delete_prefix(@options[:source_root] + '/')} to
               #{dest_path_fq.gsub(/\A#{Dir.home}/, '~').gsub(/\A#{@my_gems}/, '$my_gems')}
          END_MSG
          File.write dest_path_fq, expanded_content
          preserve_mode src_path_fq, dest_path_fq
        rescue NameError => e
          puts <<~END_MSG.red
            Error processing template #{src_path_fq}: method #{e.name} is not defined in the context where the ERB is evaluated.
          END_MSG
          nil
        end
      else
        puts "  Copying #{src_path_fq.delete_prefix(@options[:source_root] + '/')} to " \
             "#{dest_path_fq.gsub(/\A#{Dir.home}/, '~')}".green
        FileUtils.cp(src_path_fq, dest_path_fq) # Preserves file contents and permissions but not owner or group
      end
    end

    def initialize_repository
      puts "Initializing repository for the '#{@options[:gem_name]}' gem, hosted at #{@repository.host.camel_case}...".green
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

    def output_directory
      @my_gems = ENV.fetch('my_gems', nil)
      @out_dir = @my_gems ? File.join(@my_gems, @gem_name) : options[:out_dir]
      @options[:output_directory] = @out_dir
      @out_dir
    end

    def preserve_mode(source_path, dest_path)
      file_mode = File.stat(source_path).mode
      puts "  Setting #{dest_path.gsub(/\A#{Dir.home}/, '~')} to mode #{file_mode.to_s(8)}".green
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
      if source.include?('%')
        puts 'Error in template:'
        exit 6
      end
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
      unless File.exist?(filename)
        puts "Error: #{filename} does not exist, there are no TODOs to count.".red
        return 0
      end

      content = File.exist?(filename) ? File.read(filename) : ''
      content.scan('TODO').length
    end

    # Shows how many TODOs are in the gemspec and README files
    # @return [String] Multiline string indicating the number of TODOs found
    def todos_report
      gem_name = @options[:gem_name]
      gemspec_todos = todos_count File.join @options[:out_dir], "#{gem_name}.gemspec"
      readme_todos  = todos_count File.join @options[:out_dir], 'README.md'
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
