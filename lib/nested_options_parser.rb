require 'optparse'

module Nugem
  SubCmd = Struct.new(:name, :option_parser_proc) unless defined?(SubCmd)

  # Parameter block to control NestedOptionParser
  # References to other data structures can only be stored in positional parameters,
  # not keyword arguments or arguments with default values,
  # which is why option_parser_proc and help are listed first
  class NestedOptionParserControl
    attr_reader :argv, :default_option_hash, :help, :option_parser_proc, :positional_parameter_proc,
                :sub_cmds
    attr_accessor :subcommand

    # @param option_parser_proc [Proc] A proc that parses the options for a command by calling `OptionParser.on` and
    #   similar methods at least once.
    # @param help [Proc] A Method that displays help messages.
    #   It should accept an optional error message parameter.
    #   If no help proc is provided, it will not display any help messages.
    # @param positional_parameter_proc [Proc] for parsing subcommand's positional parameters
    # @param argv [Array<String>] The command line arguments to parse.
    # @param default_option_hash [Hash] Default options to be set before parsing.
    # @param sub_cmds [Array<SubCmd>] SubCmds for subcommand parser(s). The array is processed in order.
    #   Each SubCmd option_parser_proc should abe a proc that defines the options for that subcommand.
    #   If no subcommands are defined, this will be an empty array.
    # @param subcommand [SubCmd] subcommand identified on command line
    def initialize(
      option_parser_proc,
      help_proc,
      positional_parameter_proc,
      argv = [],
      default_option_hash = {},
      sub_cmds = [],
      subcommand = nil
    )
      @option_parser_proc        = option_parser_proc
      @help                      = help_proc
      @positional_parameter_proc = positional_parameter_proc
      @argv                      = argv
      @default_option_hash       = default_option_hash
      @sub_cmds                  = sub_cmds
      @subcommand                = subcommand

      @options = []
      make_procs
    end

    def complain(msg, errors_are_fatal)
      if @help
        @help.call msg, errors_are_fatal
      elsif errors_are_fatal
        exit 1
      end
    end

    def make_procs
      # All of these options can have multiple occurances on a command line, except -K/--hooks
      @jekyll_subcommand_parser_proc = SubCmd.new 'jekyll', (proc do |parser|
        parser.on '-B', '--blockn=BLOCKN' do |value|       # Specifies the name of a Jekyll no-arg block tag.
          @options[:blockn] << value
        end
        parser.on('-b', '--block=BLOCK') do |value|        # Specifies the name of a Jekyll block tag.
          @options[:block] << value
        end
        parser.on '-F', '--filter=FILTER' do |value|       # Specifies the name of a Jekyll/Liquid filter module.
          @options[:filter] << value
        end
        parser.on '-g', '--generator=GENERATOR' do |value| # Specifies a Jekyll generator.
          @options[:generator] << value
        end
        parser.on '-K', '--hooks=HOOKS'                    # Generate Jekyll hooks.
        parser.on '-T', '--tagn=TAGN' do |value|           # Specifies the name of a Jekyll no-arg tag.
          @options[:tagn] << value
        end
        parser.on '-t', '--tag=TAG' do |value|             # Specifies the name of a Jekyll tag.
          @options[:tag] << value
        end
      end)

      @option_parser_proc = proc do |parser|
        # See https://github.com/bkuhlmann/sod?tab=readme-ov-file#pathname
        parser.on '-e', '--executable EXECUTABLE' do |value|
          @options[:executable] << value
        end
        parser.on '-f', '--force',             TrueClass,            'Overwrite output directory'
        parser.on '-H', '--host=HOST',         %w[github bitbucket], 'Repository host'
        parser.on '-L', '--loglevel=LOGLEVEL', LOGLEVELS,            'Log level' # do |level|
        #   puts "level=#{level}".yellow
        # end
        parser.on('-o', '--out_dir=OUT_DIR',   Pathname, 'Output directory for the gem') do |path|
          @options[:out_dir] = create_dir path.to_s, options[:out_dir]
        end
        parser.on '-p', '--private',                    TrueClass,
                  'Publish the gem to a private repository'
        parser.on '-n', '--notodos',                    TrueClass,
                  'Suppress TODO messages in generated code'
      end
    end
  end

  class NestedOptionParser
    attr_reader :option_parser_proc, :options, :positional_parameters, :sub_cmds

    # If parsing succeeds, @options will have all options parsed from the command line
    #
    # To handle a subcommand, pass a block that yields the `NestedOptionParser` instance and a proc that parses the
    # options for the subcommand by calling `OptionParser.on` at least once.
    # The subcommand parser procs can be defined in the `subcommand_parser_procs` parameter.
    #
    # @example
    #   help = lambda do |msg = nil, errors_are_fatal = true|
    #     puts message.red if message
    #     puts <<~END_HELP
    #       This is a multiline help message.
    #       It does not exit the program.
    #     END_HELP
    #   end
    #
    #   nop_control = NestedOptionParserControl.new(
    #     option_parser_proc: proc do |parser|
    #       parser.raise_unknown = false # Required for subcommand processing to work
    #       parser.on '-h', '--help'
    #       parser.on '-o', '--out_dir OUT_DIR'
    #     end,
    #     help: method(:help),
    #     positional_parameter_proc: ::Nugem.positional_parameter_proc,
    #     argv: %w[mysubcommand pos_param2 -o /tmp/test -x -y -z]
    #     default_option_hash: { out_dir: '/home/mslinn/nugem_generated/blah', help: false },
    #     subcommand_parser_procs: [SubCmd.new('mysubcommand', proc do |parser|
    #       parser.on '-h', '--help'
    #       parser.on '-o', '--out_dir OUT_DIR'
    #     end]
    #
    #   NestedOptionParser.new nop_control
    def initialize(nop_control, errors_are_fatal: true)
      @nop_control = nop_control
      @help = nop_control.help

      # Remaining positional parameters are arguments for the subcommand, if specified
      # nop_control.default_option_hash =
      nop_control.positional_parameter_proc&.call(nop_control, errors_are_fatal: errors_are_fatal)

      # Parse common options
      @nop_control.options = evaluate(
        default_option_hash: nop_control.default_option_hash,
        option_parser_proc:  nop_control.option_parser_proc
      )
      parse_subcommand(nop_control) unless nop_control.argv.empty?
      return if nop_control.argv.empty?

      complain(errors_are_fatal)
    end

    def argv
      @nop_control.argv
    end

    private

    def complain(errors_are_fatal)
      if @help
        @help.call errors_are_fatal
      elsif errors_are_fatal
        exit 1
      end
    end

    # Process the command line arguments and update the options hash.
    #
    # If option_parser_proc raises an `OptionParser::InvalidOption` exception,
    # it is caught and an error message is displayed before the program exits.
    # Otherwise, unmatched arguments are collectded in @argv.
    #
    # @param default_option_hash [Hash] Default options to set before parsing.
    # @param arguments [Array<String>] The remaining command line arguments to parse.
    # @param option_parser_proc [Proc] The proc that defines the options for this parser.
    #
    # @yield [OptionParser, Proc] Yields the OptionParser instance and the option parser proc.
    # @yieldparam parser [OptionParser] The OptionParser instance to configure.
    #
    # @return [Hash] The options parsed from the command line arguments.
    def evaluate(default_option_hash:, option_parser_proc:)
      options = default_option_hash
      option_parser = OptionParser.new(&option_parser_proc)
      # option_parser.default_argv = @nop_control.argv
      option_parser.order! @nop_control.argv, into: options
      options
    rescue OptionParser::InvalidOption => e
      puts "Error: #{e.message}".red
      exit 1
    end

    def parse_subcommand(nop_control)
      unless nop_control.subcommand
        msg = <<~END_MSG
          No subcommand parsing was defined for the following arguments:\n  #{nop_control.argv.join ' '}
        END_MSG
        nop_control.complain(msg, errors_are_fatal)
        return
      end

      @options = evaluate(
        default_option_hash: @options,
        option_parser_proc:  nop_control.subcommand.option_parser_proc
      )
    end
  end
end
