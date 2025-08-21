require 'optparse'

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
  end

  def complain(msg, errors_are_fatal)
    if @help
      @help.call msg, errors_are_fatal
    elsif errors_are_fatal
      exit 1
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
    @options = evaluate(
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
      nop_control.help.call errors_are_fatal
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
      option_parser_proc:  nop_control.option_parser_proc
    )
  end
end
