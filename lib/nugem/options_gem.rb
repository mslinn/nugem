require 'fileutils'
require 'sod'
require 'sod/types/pathname'

module Nugem
  HOSTS = %w[github gitlab bitbucket].freeze
  LOGLEVELS = %w[trace debug verbose info warning error fatal panic quiet].freeze

  def self.help(msg = nil, errors_are_fatal: true)
    printf "Error: #{msg}\n\n".yellow if msg
    msg = <<~END_HELP
      nugem: Creates scaffolding for a plain gem or a Jekyll plugin.
      (Jekyll plugins are a type of specialized gem.)

      nugem [OPTIONS] gem NAME     # Creates the scaffold for implementing a new plain-old Ruby gem called NAME.
      nugem [OPTIONS] jekyll NAME  # Creates the scaffold for a new Jekyll plugin called NAME.

      The following OPTIONS are available for all gem types:

        -e NAME1[,NAME2...], --executables NAME1[,NAME2...] # Include executables with the given names for the gem.
        -h, --help                                          # Display this help message
        -H HOST, --host=HOST                                # Repository host. Default: github
                                                            # Possible values: #{HOSTS.join ', '}
        -L LOGLEVEL, --loglevel LOGLEVEL                    # Possible values: #{LOGLEVELS.join ', '}.
                                                            # Default: info
        -o OUT_DIR, --out-dir=OUT_DIR                       # Output directory for the gem. Default: ~/nugem_generated
        -N, --no-todos                                      # Suppress TODO: messages in generated code. Default: false
        -p, --private                                       # Publish the gem to a private repository. Default: false
        -y, --yes                                           # Answer yes to all questions. Default: false

      The following options are only available for Jekyll plugins.
      Each of these OPTIONs can be invoked multiple times, except -K / --hooks:
        -B BLOCK1[,BLOCK2...], --blocks=BLOCK1[,BLOCK2...]                      # Specifies the name of a Jekyll block tag.
        -N BLOCK1[,BLOCK2...], --blockns=BLOCK1[,BLOCK2...]                     # Specifies the name of Jekyll no-arg block tag(s).
        -f FILTER1[,FILTER2...], --filters=FILTER1[,FILTER2...]                 # Specifies the name of a Jekyll/Liquid filter module.
        -g GENERATOR1[,GENERATOR2...], --generators=GENERATOR1[,GENERATOR2...]  # Specifies Jekyll generator(s).
        -K HOOKS, --hooks=HOOKS                                                 # Specifies Jekyll hooks.
        -t TAG1[,TAG2...], --tags=TAG1[,TAG2...]                                # Specifies the name of Jekyll tag(s).
        -n TAG1[,TAG2...], --tagns=TAG1[,TAG2...]                               # Specifies the name of Jekyll no-arg tag(s).
    END_HELP
    printf msg.cyan
    exit 1 if errors_are_fatal
  end

  class Options
    attr_reader :attribute_name, :value
    attr_accessor :errors_are_fatal, :options

    include ::HighlineWrappers

    def initialize(errors_are_fatal: true)
      @attribute_name = 'plain'
      @errors_are_fatal = errors_are_fatal

      @value = {
        executables: false,
        gem_type:    :plain,
        host:        'github',
        loglevel:    LOGLEVELS[3], # Default is 'info'
        out_dir:     "#{Dir.home}/nugem_generated",
        private:     false,
        todos:       true,
        yes:         false,
      }
    end

    # Do application-level sanity check stuff
    # Called after user parameters have been gathered and saved as state in this instance
    # Only generate output if loglevel is info or lower
    def act(options, parse_dry_run: false)
      dir = options[:out_dir]
      overwrite = options[:overwrite]
      show_log_level_info = LOGLEVELS.index(options[:loglevel]) < LOGLEVELS.index('info')

      if parse_dry_run
        puts "Dry run: skipping the removal of #{dir}".yellow if overwrite && show_log_level_info
      else
        puts "Removing #{dir}".yellow if show_log_level_info
        FileUtils.rm_rf(Dir.glob(dir), force: true, secure: true)
        Dir.mkdir dir
      end
      summarize(options) if show_log_level_info
    end

    def summarize(options)
      executable_msg = if options[:executables]
                         if options[:executables].length > 1
                           "Executables called #{options[:executables].join ', '} will be included"
                         else
                           "An executable called #{options[:executables].join} will be included"
                         end
                       else
                         'No executables will be included'
                       end
      yes_msg = if options[:yes]
                  "All questions will be automatically be answered with 'yes'"
                else
                  'User responses will be used for yes/no questions'
                end
      <<~END_SUMMARY
        Loglevel #{options[:loglevel]}
        Output directory: '#{options[:out_dir]}'
        #{executable_msg}
        Git host: #{options[:host]}
        A #{options[:private] ? 'private' : 'public'} git repository will be created
        TODOs #{options[:todos] ? 'will' : 'will not'} be included in the source code
        #{yes_msg}
      END_SUMMARY
    end

    def parse_dir(dir, default_value)
      dir ||= default_value
      if Dir.exist?(dir) && !Dir.empty?(dir)
        puts "Output directory '#{dir}' already exists and is not empty."
        @options[:overwrite] = if options[:yes]
                                 puts "Overwriting contents of #{dir} because --yes was specified."
                                 true
                               else
                                 ask "Do you want to overwrite the contents of #{dir}? (y/n)"
                               end
      end
      dir
    end

    # Gather all the possible parameter values. Other than built-in type checking,
    # act_and_summarize will do the the application-level sanity check stuff
    def parse_options(argv_override: nil)
      options = @value
      # @return hash containing options
      # See https://ruby-doc.org/3.4.1/stdlibs/optparse/OptionParser.html
      # See https://ruby-doc.org/3.4.1/optparse/option_params_rdoc.html
      OptionParser.new do |parser|
        parser.default_argv = argv_override if argv_override

        # See https://github.com/bkuhlmann/sod?tab=readme-ov-file#pathname
        parser.on('-e', '--executables EXECUTABLES', String,
                  'Include executables with the given names for the generated gem; separate with commas') do |value|
          value.split(',')
        end
        parser.on '-H', '--host HOST',              %w[github bitbucket], 'Repository host'
        parser.on '-L', '--loglevel LOGLEVEL',      LOGLEVELS,            'Logging level'
        parser.on('-o', '--out_dir OUT_DIR',        Pathname,             'Output directory for the gem') do |dir|
          options[:out_dir] = parse_dir dir, options[:out_dir]
        end
        parser.on '-p', '--private',                TrueClass,             'Publish the gem to a private repository'
        parser.on '-N', '--no-todos',               TrueClass,             'Generate TODO: messages in generated code'
        parser.on '-y', '--yes',                    TrueClass,             'Answer yes to all questions'
        parser.on_tail('-h', '--help',                                     'Show this message') do
          ::Nugem.help(errors_are_fatal: errors_are_fatal)
        end
      end.order! into: options
      options
    rescue OptionParser::InvalidOption => e
      ::Nugem.help(e.message, errors_are_fatal: errors_are_fatal)
    end

    def parse_positional_parameters(label = 'gem')
      ::Nugem.help("The type and name of the #{label} to create was not specfied.", errors_are_fatal: errors_are_fatal) if ARGV.empty?
      ::Nugem.help('Invalid syntax.', errors_are_fatal: errors_are_fatal) if ARGV.length > 2

      @options[:gem_type] = ARGV[0]
      @options[:gem_name] = ARGV[1]

      ::Nugem.help("Invalid #{@options[:gem_type]} name.", errors_are_fatal: errors_are_fatal) unless Nugem.validate_gem_name(@options[:gem_name])
    end
  end
end
