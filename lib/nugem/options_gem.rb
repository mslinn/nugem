require 'fileutils'

module Nugem
  VERBOSITY = %w[trace debug verbose info warning error fatal panic quiet].freeze

  def self.help(msg = nil)
    printf "Error: #{msg}\n\n".yellow unless msg.nil?
    msg = <<~END_HELP
      nugem: Creates scaffolding for a plain gem or a Jekyll gem.

      nugem gem NAME        # Creates a new gem scaffold.
      nugem jekyll NAME     # Creates a new Jekyll plugin scaffold.

      Options can be placed anywhere on the command line.
      The following options are always available:

        -o OUT_DIR, --out-dir=OUT_DIR        # Output directory for the gem. Default: ~/nugem_generated
        -e, --executable                     # Include an executable for the gem. Default: false
        -h HOST, --host=HOST                 # Repository host. Default: github
                                             # Possible values: bitbucket, github, gitlab
        -p, --private                        # Publish the gem to a private repository. Default: false
        -y, --yes                            # Answer yes to all questions. Default: false
        -v VERBOSITY, --verbosity VERBOSITY  # Possible values: #{VERBOSITY.join ', '}. Default: info
        -t, --todos                          # Generate TODO: messages in generated code. Default: true

      The following options are only available for Jekyll gems and canbe invoked multiple times:
        --block=BLOCK                                         # Specifies the name of a Jekyll block tag.
        --blockn=BLOCKN                                       # Specifies the name of a Jekyll no-arg block tag.
        --filter=FILTER                                       # Specifies the name of a Jekyll/Liquid filter module.
        --generator=GENERATOR                                 # Specifies a Jekyll generator.
        --hooks=HOOKS                                         # Specifies Jekyll hooks.
        --tag=TAG                                             # Specifies the name of a Jekyll tag.
        --tagn=TAGN                                           # Specifies the name of a Jekyll no-arg tag.
    END_HELP
    printf msg.cyan
    exit 1
  end

  class Options
    def initialize
      @attribute_name = 'plain'

      @default_options = {
        executable: false,
        gem_type:   :plain,
        host:       'github',
        loglevel:   VERBOSITY[4], # Default is 'warning'
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

    def parse_options
      options = @default_options
      # @return hash containing options
      # See https://ruby-doc.org/3.4.1/stdlibs/optparse/OptionParser.html
      # See https://ruby-doc.org/3.4.1/optparse/option_params_rdoc.html
      OptionParser.new do |parser|
        parser.program_name = File.basename __FILE__
        @parser = parser

        parser.on('-e', '--executable', FalseClass, 'Include an executable for the generated gem')
        parser.on('-HHOST', '--host', %w[github bitbucket], 'Repository host')
        parser.on('GEM_NAME', 'Repository host')
        parser.on('-oOUT_DIR', '--out_dir', 'Output directory for the gem') do |dir|
          dir ||= options[:out_dir]
          if Dir.exist?(dir) && !Dir.empty?(dir)
            puts "Output directory '#{dir}' already exists and is not empty."
            overwrite = if options[:yes]
                          puts "Overwriting contents of #{dir} because --yes was specified."
                          true
                        else
                          ask "Do you want to overwrite the contents of #{dir}? (y/n)"
                        end
            if overwrite
              FileUtils.rm_r Dir.glob(dir), force: true, secure: true
              Dir.mkdir dir
            end
          end
          puts "Output directory set to '#{dir}'."
          options[:out_dir] = dir
        end
        parser.on '-lLOGLEVEL', '--loglevel', VERBOSITY,  'Logging level'
        parser.on '-p',         '--private',  FalseClass, 'Publish the gem to a private repository'
        parser.on '-t',         '--todos',    TrueClass,  'Generate TODO: messages in generated code'
        parser.on '-y',         '--yes',      FalseClass, 'Answer yes to all questions'

        parser.on_tail('-h', '--help', 'Show this message') do
          help
        end
      end.order! into: options
      options
    end

    def parse_positional_parameters(label = 'gem')
      help("The type and name of the #{label} to create was not specfied.") if ARGV.empty?
      help('Invalid syntax.') if ARGV.length > 2

      @options[:gem_type] = ARGV[0]
      @options[:gem_name] = ARGV[1]

      help("Invalid #{@options[:gem_type]} name.") unless Nugem.validate_gem_name(@options[:gem_name])
    end
  end
end
