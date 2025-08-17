require 'optparse'

SubCmd = Struct.new(:name, :option_parser_proc)

# Parameter block to control NestedOptionParser
# References to other data structures can only be stored in positional parameters,
# not keyword arguments or arguments with default values,
# which is why option_parser_proc and help are listed first
class NestedOptionParserControl
  attr_reader :argv, :default_option_hash, :help, :option_parser_proc, :positional_parameter_proc, :sub_cmds

  def initialize(
    option_parser_proc,
    help,
    positional_parameter_proc,
    argv = [],
    default_option_hash = {},
    sub_cmds = []
  )
    @option_parser_proc        = option_parser_proc
    @help                      = help
    @positional_parameter_proc = positional_parameter_proc
    @argv                      = argv
    @default_option_hash       = default_option_hash
    @sub_cmds                  = sub_cmds
  end
end

class NestedOptionParser
  attr_reader :option_parser_proc, :options, :positional_parameters, :sub_cmds

  # If parsing succeeds, @options will have all options parsed from the command line
  # Please see [`subcommands.md`](subcommands.md) for an example of how to use this class.
  #
  # To handle a subcommand, pass a block that yields the `NestedOptionParser` instance and a proc that parses the
  # options for the subcommand by calling `OptionParser.on` at least once.
  # The subcommand parser procs can be defined in the `subcommand_parser_procs` parameter.
  #
  # @param argv [Array<String>] The command line arguments to parse.
  # @param default_option_hash [Hash] Default options to be set before parsing.
  # @param option_parser_proc [Proc] A proc that parses the options for a command by calling `OptionParser.on` and
  # similar methods at least once.
  # @param help [Proc] A Method that displays help messages.
  #   It should accept an optional error message parameter.
  #   If no help proc is provided, it will not display any help messages.
  # @param sub_cmds [Array<SubCmd>] SubCmds for subcommand parser(s). The array is processed in order.
  #   Each SubCmd option_parser_proc should abe a proc that defines the options for that subcommand.
  #   If no subcommands are defined, this will be an empty array.
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
  #   nested_option_parser_control = NestedOptionParserControl.new(
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
  #   NestedOptionParser.new nested_option_parser_control
  def initialize(nested_option_parser_control, errors_are_fatal: true)
    @nested_option_parser_control = nested_option_parser_control
    @help = nested_option_parser_control.help

    # nested_option_parser_control.argv might contain positional parameters now
    unless nested_option_parser_control.argv&.first&.start_with?('-')
      subcommand_name = nested_option_parser_control.argv&.shift
      subcommand = nested_option_parser_control.sub_cmds.find do |sub_cmd|
        sub_cmd.name == subcommand_name
      end
      if subcommand.nil? && !subcommand_name.empty?
        msg = "Error: No parsing was defined for subcommand '#{subcommand_name}'"
        @help&.call msg.red, errors_are_fatal
        return
      end
    end

    # nested_option_parser_control.default_option_hash =
    # TODO Verify that nested_option_parser_control.argv and default_option_hash are updated
    nested_option_parser_control.positional_parameter_proc&.call(nested_option_parser_control)

    # TODO: Verify there are no positional parameters at the start of argv now

    # Parse common options
    @options = evaluate(
      default_option_hash: nested_option_parser_control.default_option_hash,
      option_parser_proc:  nested_option_parser_control.option_parser_proc
    )
    return if subcommand_name.to_s.strip.empty?

    @options = evaluate(
      default_option_hash: @options,
      option_parser_proc:  subcommand.option_parser_proc
    )
    return if nested_option_parser_control.argv.to_s.strip.empty?

    if nested_option_parser_control.help
      msg = <<~END_MSG
        Error: The following unrecognized options were found on the command line:\n#{@argv}
      END_MSG
      nested_option_parser_control.help.call msg, errors_are_fatal
    elsif errors_are_fatal
      exit 1
    end
  end

  def argv
    @nested_option_parser_control.argv
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
    # option_parser.default_argv = @nested_option_parser_control.argv
    option_parser.order! @nested_option_parser_control.argv, into: options
    options
  rescue OptionParser::InvalidOption => e
    puts "Error: #{e.message}".red
    exit 1
  end
end
