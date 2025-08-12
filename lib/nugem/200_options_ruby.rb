require 'fileutils'
require 'sod'
require 'sod/types/pathname'

module Nugem
  DEFAULT_OUT_DIR_BASE = File.join(Dir.home, 'nugem_generated').freeze
  HOSTS = %w[github gitlab bitbucket].freeze
  LOGLEVELS = %w[trace debug verbose info warning error fatal panic quiet].freeze

  class << self; attr_accessor :help_proc, :positional_parameter_proc; end

  ::Nugem.help_proc = lambda do |msg = nil, errors_are_fatal = true|
    printf "Error: #{msg}\n\n".yellow if msg
    msg = <<~END_HELP
      nugem v#{VERSION}: Creates scaffolding for a Ruby gem or a Jekyll plugin.
      (Jekyll plugins are a specialized type of Ruby gem.)

      nugem [OPTIONS] ruby NAME    # Creates the scaffold for a new Ruby gem called NAME.
      nugem [OPTIONS] jekyll NAME  # Creates the scaffold for a new Jekyll plugin called NAME.

      The following OPTIONS are available for all gem types:
        -f, --force                       # Delete output directory if it exists before generating output
        -h, --help                        # Display this help message and exit
        -H HOST, --host=HOST              # Repository host. Default: github
                                          # Possible values: #{HOSTS.join ', '}
        -L LOGLEVEL, --loglevel=LOGLEVEL  # Possible values: #{LOGLEVELS.join ', '}.
                                          # Default: info
        -o OUT_DIR, --out-dir=OUT_DIR     # Output directory for the gem. Default: ~/nugem_generated/NAME
        -N, --no-todos                    # Suppress TODO: messages in generated code. Default: false
        -p, --private                     # Publish the gem to a private repository. Default: false
      Each of these OPTIONs can be invoked multiple times:
        -e NAME1, --executables=NAME1     # Include an executable with the given name for the gem

      The following options are only available for Jekyll plugins.
        -K HOOKS, --hooks=HOOKS                # Generate Jekyll hooks.
      Each of these OPTIONs can be invoked multiple times:
        -B BLOCK1, --block=BLOCK1              # Specifies the name of a Jekyll block tag.
        -N BLOCK1, --blockn=BLOCK1             # Specifies the name of a Jekyll no-arg block tag.
        -f FILTER1, --filter=FILTER1           # Specifies the name of a Jekyll/Liquid filter module.
        -g GENERATOR1, --generator=GENERATOR1  # Specifies the name of a Jekyll generator.
        -t TAG1, --tag=TAG1                    # Specifies the name of a Jekyll tag.
        -n TAG1, --tagn=TAG1                   # Specifies the name of a Jekyll no-arg tag.
    END_HELP
    printf msg.cyan
    return unless errors_are_fatal

    exit(1)
  end

  # This defines how positional parameters are extracted from
  # the copy of the command line used by module Nugem
  # @param nop [NestedOptionParser] nop.argv should be modified
  # @return default_option_hash (Hash)
  ::Nugem.positional_parameter_proc = proc do |nop|
    if nop.argv&.first&.start_with?('-')
      @help.call 'No subcommand type was provided on the command line', true
    else
      gem_type = nop.argv.shift
      nop.default_option_hash['gem_type'] = gem_type
      if nop.argv&.first&.start_with?('-')
        @help.call "No #{gem_type} name was provided on the command line", true
      else
        nop.default_option_hash['gem_name'] = @argv&.shift
      end
    end
    nop.default_option_hash
  end

  class Options
    attr_accessor :errors_are_fatal, :options, :option_parser_proc

    include ::HighlineWrappers

    def initialize(default_options, dry_run: false, errors_are_fatal: true)
      @errors_are_fatal = errors_are_fatal
      @options = default_options
                   .merge({ # Ruby gem options
                            executable: [],
                            dry_run:    dry_run,
                            force:      false,
                            host:       'github',
                            loglevel:   LOGLEVELS[3], # Default is 'info'
                            out_dir:    "#{DEFAULT_OUT_DIR_BASE}/#{default_options[:gem_name]}",
                            overwrite:  false,
                            private:    false,
                            todos:      true,
                          })
                   .merge({ # Jekyll plugin options
                            block:     [],
                            blockn:    [],
                            filter:    [],
                            generator: [],
                            tag:       [],
                            tagn:      [],
                          })
                   .sort
                   .to_h
      @option_parser_proc = proc do |parser|
        # See https://github.com/bkuhlmann/sod?tab=readme-ov-file#pathname
        parser.on '-e', '--executable EXECUTABLE' do |value|
          options[:executable] << value
        end
        parser.on '-f', '--force',             TrueClass,            'Overwrite output directory'
        parser.on '-H', '--host=HOST',         %w[github bitbucket], 'Repository host'
        parser.on '-L', '--loglevel=LOGLEVEL', LOGLEVELS,            'Log level' # do |level|
        #   puts "level=#{level}".yellow
        # end
        parser.on('-o', '--out_dir=OUT_DIR',   Pathname, 'Output directory for the gem') do |path|
          options[:out_dir] = create_dir path.to_s, options[:out_dir]
        end
        parser.on '-p', '--private',                    TrueClass,
                  'Publish the gem to a private repository'
        parser.on '-n', '--notodos',                    TrueClass,
                  'Suppress TODO messages in generated code'
      end

      subcommand_parser_proc = SubCmd.new('jekyll', proc do |parser|
        # All of the following can have multiple occurances on a command line, except hooks
        parser.on '-B', '--blockn=BLOCKN' do |value|       # Specifies the name of a Jekyll no-arg block tag.
          options[:blockn] << value
        end
        parser.on('-b', '--block=BLOCK') do |value|        # Specifies the name of a Jekyll block tag.
          options[:block] << value
        end
        parser.on '-F', '--filter=FILTER' do |value|       # Specifies the name of a Jekyll/Liquid filter module.
          options[:filter] << value
        end
        parser.on '-g', '--generator=GENERATOR' do |value| # Specifies a Jekyll generator.
          options[:generator] << value
        end
        parser.on '-K', '--hooks=HOOKS'                    # Generate Jekyll hooks.
        parser.on '-T', '--tagn=TAGN' do |value|           # Specifies the name of a Jekyll no-arg tag.
          options[:tagn] << value
        end
        parser.on '-t', '--tag=TAG' do |value|             # Specifies the name of a Jekyll tag.
          options[:tag] << value
        end
      end)
      @subcommand_parser_procs = [subcommand_parser_proc]
    end

    def create_dir(dir, default_value)
      dir ||= default_value
      if Dir.exist?(dir) && !Dir.empty?(dir)
        puts "Output directory '#{dir}' already exists and is not empty."
        return dir if @options[:dry_run]

        if @options[:overwrite]
          puts "Overwriting contents of #{dir} because --force was specified."
        else
          @options[:overwrite] = ask "Do you want to overwrite the contents of #{dir}? (y/n)"
        end
      end
      dir
    end

    # Gather all the possible parameter values and performs type checking.
    # Subsequent methods must perform application-level sanity checks.
    def nested_option_parser_from(argv_override)
      # @return hash containing options
      # See https://ruby-doc.org/3.4.1/stdlibs/optparse/OptionParser.html
      # See https://ruby-doc.org/3.4.1/optparse/option_params_rdoc.html
      nested_option_parser_control = NestedOptionParserControl.new(
        @option_parser_proc,
        ::Nugem.help_proc,
        argv_override,
        @options,
        @subcommand_parser_procs
      )
      NestedOptionParser.new nested_option_parser_control, errors_are_fatal: @errors_are_fatal
    rescue OptionParser::InvalidOption => e
      ::Nugem.help.call(e.message, errors_are_fatal: @errors_are_fatal)
      e.message # Useful for rspec tests
    end

    # Do application-level sanity check stuff then summarize if log level sufficient
    # Called after user parameters have been gathered and saved as state in this instance
    # Only generate output if loglevel is info or lower
    def prepare_and_report
      dir = @options[:out_dir]
      overwrite = @options[:overwrite]
      show_log_level_info = LOGLEVELS.index(@options[:loglevel]) <= LOGLEVELS.index('info')

      if @options[:dry_run]
        puts "Dry run: skipping the removal of #{dir}".yellow if overwrite && show_log_level_info
      else
        puts "Removing #{dir}".yellow if show_log_level_info
        FileUtils.rm_rf(Dir.glob(dir), secure: true)
        Dir.mkdir dir
      end
      show_log_level_info ? summarize : ''
    end

    def summarize
      executable_msg = if @options[:executable].empty?
                         'No executables will be included'
                       elsif @options[:executable].length > 1
                         "Executables called #{@options[:executable].join ', '} will be included"
                       else
                         "An executable called #{@options[:executable].join} will be included"
                       end
      force_msg = if @options[:force]
                    'Any pre-existing content in the output directory will be deleted before generating new output.'
                  else
                    'Pre-existing content in the output directory will abort the program.'
                  end
      <<~END_SUMMARY
        Options:
         - Gem type: #{@options[:gem_type]}
         - Loglevel #{@options[:loglevel]}
         - Output directory: '#{@options[:out_dir]}'
         - #{force_msg}
         - #{executable_msg}
         - Git host: #{@options[:host]}
         - A #{@options[:private] ? 'private' : 'public'} git repository will be created
         - TODOs #{@options[:notodos] ? 'will not' : 'will'} be included in the source code
      END_SUMMARY
    end
  end
end
