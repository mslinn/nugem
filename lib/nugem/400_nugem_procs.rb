module Nugem
  class << self
    attr_accessor :common_parser_proc, :help_proc, :jekyll_plugin_options, :jekyll_subcommand,
                  :jekyll_subcommand_parser_proc, :positional_parameter_proc
  end

  # Common, or base parameter parsing, common to all subcommands.
  self.common_parser_proc = proc do |parser, options|
    # See https://github.com/bkuhlmann/sod?tab=readme-ov-file#pathname
    parser.on '-e', '--executable EXECUTABLE' do |value|
      options[:executables] << value
    end
    parser.on '-f', '--force',             TrueClass,            'Overwrite output directory'
    parser.on '-H', '--host=HOST',         %w[github bitbucket], 'Repository host'
    parser.on '-L', '--loglevel=LOGLEVEL', LOGLEVELS,            'Log level' # do |level|
    #   puts "level=#{level}".yellow
    # end
    parser.on('-o', '--out_dir=OUT_DIR',   Pathname, 'Output directory for the gem') do |path|
      options[:out_dir] = path.to_s # TODO: elsewhere: create_dir path.to_s, options[:out_dir]
    end
    parser.on '-p', '--private',                    TrueClass,
              'Publish the gem to a private repository'
    parser.on '-n', '--notodos',                    TrueClass,
              'Suppress TODO messages in generated code'
  end

  self.help_proc = lambda do |msg = nil, errors_are_fatal = true|
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

  self.jekyll_plugin_options = {
    block:     [],
    blockn:    [],
    filter:    [],
    generator: [],
    tag:       [],
    tagn:      [],
  }

  # All of these options can have multiple occurances on a command line, except -K/--hooks
  self.jekyll_subcommand_parser_proc = proc do |parser, options|
    parser.on '-B', '--blockn=BLOCKN' do |value| # Specifies the name of a Jekyll no-arg block tag.
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
  end

  # This defines how positional parameters are extracted from
  # the copy of the command line used by module Nugem
  # @param nop [NestedOptionParser] nop.argv should be modified
  # @return default_option_hash (Hash)
  self.positional_parameter_proc = proc do |nop, errors_are_fatal = true|
    if nop.argv.empty? ||
       nop.argv.length < 2 ||
       nop.argv[0..1].any? { |x| x.start_with?('-') }
      ::Nugem.help_proc.call 'Either the subcommand type or name was not provided on the command line',
                             errors_are_fatal: errors_are_fatal
    else
      nop.default_option_hash[:gem_type] = nop.argv.shift
      nop.default_option_hash[:gem_name] = nop.argv.shift
    end
    nop.default_option_hash
  end

  def self.make_subcommands
    @jekyll_subcommand = SubCmd.new 'jekyll', jekyll_subcommand_parser_proc
  end
end
