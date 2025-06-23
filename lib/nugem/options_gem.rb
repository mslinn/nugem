require 'fileutils'

module Nugem
  HOSTS = %w[github gitlab bitbucket].freeze
  LOGLEVELS = %w[trace debug verbose info warning error fatal panic quiet].freeze

  def self.help(msg = nil)
    printf "Error: #{msg}\n\n".yellow if msg
    msg = <<~END_HELP
      nugem: Creates scaffolding for a plain gem or a Jekyll plugin.
      (Jekyll plugins are a type of specialized gem.)

      nugem [OPTIONS] gem NAME     # Creates the scaffold for implementing a new plain-old Ruby gem called NAME.
      nugem [OPTIONS] jekyll NAME  # Creates the scaffold for a new Jekyll plugin called NAME.

      The following OPTIONS are available for all gem types:

        -e, --executable                     # Include an executable for the gem. Default: false
        -h, --help                           # Display this help message
        -H HOST, --host=HOST                 # Repository host. Default: github
                                             # Possible values: #{HOSTS.join ', '}
        -L LOGLEVEL, --loglevel LOGLEVEL     # Possible values: #{LOGLEVELS.join ', '}. Default: info
        -o OUT_DIR, --out-dir=OUT_DIR        # Output directory for the gem. Default: ~/nugem_generated
        -p, --private                        # Publish the gem to a private repository. Default: false
        -T, --todos                          # Generate TODO: messages in generated code. Default: true
        -y, --yes                            # Answer yes to all questions. Default: false

      The following options are only available for Jekyll plugin.
      Each of these OPTIONs can be invoked multiple times, except -K / --hooks:
        -B BLOCK, --block=BLOCK              # Specifies the name of a Jekyll block tag.
        -f FILTER, --filter=FILTER           # Specifies the name of a Jekyll/Liquid filter module.
        -g GENERATOR, --generator=GENERATOR  # Specifies a Jekyll generator.
        -K HOOKS, --hooks=HOOKS              # Specifies Jekyll hooks.
        -n TAGN, --tagn=TAGN                 # Specifies the name of a Jekyll no-arg tag.
        -N BLOCKN, --blockn=BLOCKN           # Specifies the name of a Jekyll no-arg block tag.
        -t TAG, --tag=TAG                    # Specifies the name of a Jekyll tag.
    END_HELP
    printf msg.cyan
    exit 1
  end

  class Options
    attr_reader :attribute_name, :default_options, :options

    include ::HighlineWrappers

    def initialize
      @attribute_name = 'plain'

      @default_options = {
        executable: false,
        gem_type:   :plain,
        host:       'github',
        loglevel:   LOGLEVELS[3], # Default is 'info'
        out_dir:    "#{Dir.home}/nugem_generated",
        private:    false,
        quiet:      true,
        todos:      true,
        yes:        false,
      }
    end

    # Do application-level sanity check stuff
    # Called after user parameters have been gathered and saved as state in this instance
    # Only generate output if loglevel is info or lower
    def act_and_summarize(options, parse_dry_run: false)
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
      return unless show_log_level_info

      executable_msg = options[:executable] ? "An executable called #{options[:executable]} will be included" : 'No executable will be included'
      yes_msg = options[:yes] ? "All questions will be automatically be answered with 'yes'." : 'User responses will be used for yes/no questions.'
      puts <<~END_SUMMARY.green
        Loglevel #{LOGLEVELS.index(options[:loglevel])}
        Output directory: '#{dir}'
        #{executable_msg}
        Git host: #{options[:host]}
        A #{options[:private] ? 'private' : 'public'} git repository will be created
        TODOs #{options[:todos] ? 'will' : 'will not'} be included in the source code
        #{yes_msg}
      END_SUMMARY
    end

    # Defines a new attribute called `prop_name` in object `obj` and sets it to `prop_value`
    def attribute_new(prop_name, prop_value)
      obj = self.class.module_eval { attr_accessor @attribute_name } # idempotent
      obj.class.module_eval { attr_accessor prop_name }
      obj.instance_variable_set :"@#{prop_name}", prop_value
    end

    # Defines sub-attributes for the object attribute called @attribute_name
    # @param hash simple name/value pairs, nothing nested
    def attributes_from_hash(hash)
      hash.each { |key, value| attribute_new key, value }
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
      options = @default_options
      # @return hash containing options
      # See https://ruby-doc.org/3.4.1/stdlibs/optparse/OptionParser.html
      # See https://ruby-doc.org/3.4.1/optparse/option_params_rdoc.html
      OptionParser.new do |parser|
        parser.default_argv = argv_override if argv_override
        parser.program_name = File.basename __FILE__
        @parser = parser

        # TODO: how to parse more than one executable?
        parser.on '-eEXECUTABLE', '--executable', FalseClass,           'Include an executable with the given name for the generated gem'
        parser.on '-HHOST',       '--host',       %w[github bitbucket], 'Repository host'
        parser.on '-LLOGLEVEL',   '--loglevel',   LOGLEVELS,            'Logging level'
        parser.on('-oOUT_DIR',    '--out_dir',                          'Output directory for the gem') do |dir|
          options[:out_dir] = parse_dir dir, options[:out_dir]
        end
        parser.on '-p',           '--private',  FalseClass,            'Publish the gem to a private repository'
        parser.on '-T',           '--todos',    TrueClass,             'Generate TODO: messages in generated code'
        parser.on '-y',           '--yes',      FalseClass,            'Answer yes to all questions'
        parser.on_tail('-h',      '--help',                            'Show this message') do
          ::Nugem.help
        end
      end.order! into: options
      options
    end

    def parse_positional_parameters(label = 'gem')
      ::Nugem.help("The type and name of the #{label} to create was not specfied.") if ARGV.empty?
      ::Nugem.help('Invalid syntax.') if ARGV.length > 2

      @options[:gem_type] = ARGV[0]
      @options[:gem_name] = ARGV[1]

      ::Nugem.help("Invalid #{@options[:gem_type]} name.") unless Nugem.validate_gem_name(@options[:gem_name])
    end
  end
end
