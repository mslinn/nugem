require 'fileutils'

module Nugem
  HOSTS = %w[github gitlab bitbucket].freeze
  LOGLEVELS = %w[trace debug verbose info warning error fatal panic quiet].freeze

  def self.help(msg = nil)
    printf "Error: #{msg}\n\n".yellow if msg
    msg = <<~END_HELP
      nugem: Creates scaffolding for a plain gem or a Jekyll plugin.
      (Jekyll plugins are specialized gems.)

      nugem [OPTIONS] gem NAME        # Creates the scaffold for a new gem called NAME.
      nugem [OPTIONS] jekyll NAME     # Creates the scaffold for a new Jekyll plugin called NAME.

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

    def parse_dir(dir, default_value, dry_run: false)
      dir ||= default_value
      if Dir.exist?(dir) && !Dir.empty?(dir)
        puts "Output directory '#{dir}' already exists and is not empty."
        overwrite = if options[:yes]
                      puts "Overwriting contents of #{dir} because --yes was specified."
                      true
                    else
                      ask "Do you want to overwrite the contents of #{dir}? (y/n)"
                    end
        if overwrite && !dry_run
          FileUtils.rm_r Dir.glob(dir), force: true, secure: true
          Dir.mkdir dir
        end
      end
      dir
    end

    # Only generate output if loglevel is info or lower
    def summarize(options)
      return if LOGLEVELS.index(options[:loglevel]) < LOGLEVELS.index('info')

      puts "Output directory is '#{options[:out_dir]}'.".green
    end

    def parse_options(parse_dry_run: true)
      options = @default_options
      # @return hash containing options
      # See https://ruby-doc.org/3.4.1/stdlibs/optparse/OptionParser.html
      # See https://ruby-doc.org/3.4.1/optparse/option_params_rdoc.html
      OptionParser.new do |parser|
        parser.program_name = File.basename __FILE__
        @parser = parser

        parser.on '-e',         '--executable', FalseClass, 'Include an executable for the generated gem'
        parser.on '-HHOST',     '--host', %w[github bitbucket], 'Repository host'
        parser.on '-LLOGLEVEL', '--loglevel', LOGLEVELS, 'Logging level'
        parser.on('-oOUT_DIR',  '--out_dir', 'Output directory for the gem') do |dir|
          options[:out_dir] = parse_dir dir, options[:out_dir], parse_dry_run
        end
        parser.on '-p',         '--private',  FalseClass, 'Publish the gem to a private repository'
        parser.on '-T',         '--todos',    TrueClass,  'Generate TODO: messages in generated code'
        parser.on '-y',         '--yes',      FalseClass, 'Answer yes to all questions'
        parser.on_tail('-h',    '--help', 'Show this message') do
          ::Nugem.help
        end
      end.order! into: options
      summarize options
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
