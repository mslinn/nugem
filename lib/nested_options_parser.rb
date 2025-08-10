require 'optparse'

SubCmd = Struct.new(:name, :option_parser_proc)

NestedOptionParserControl = Struct.new(
  :option_parser_proc,
  :argv,
  :default_option_hash,
  :help,
  :sub_cmds
) do
  def initialize(
    option_parser_proc,
    argv = [],
    default_option_hash = {},
    help = nil,
    sub_cmds = []
  )
    super
  end
end

class NestedOptionParser
  attr_reader :option_parser_proc, :options, :positional_parameters, :remaining_options, :sub_cmds

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
  # def help(message = nil)
  #   puts message.red if message
  #   puts <<~END_HELP
  #     This is a multiline help message.
  #     It does not exit the program.
  #   END_HELP
  # end
  #
  # NestedOptionParser.new(
  #   argv: %w[mysubcommand pos_param2 -o /tmp/test -x -y -z]
  #   default_option_hash: { help: false },
  #   option_parser_proc: proc do |parser|
  #     parser.on '-h', '--help'
  #     parser.on '-o', '--out_dir OUT_DIR'
  #   end,
  #   help: method(:help),
  #   subcommand_parser_procs: [SubCmd.new('mysubcommand', proc do |parser|
  #     parser.on '-h', '--help'
  #     parser.on '-o', '--out_dir OUT_DIR'
  #   end]
  # )
  def initialize(nested_option_parser_control)
    @help = nested_option_parser_control.help
    @sub_cmds = nested_option_parser_control.sub_cmds
    @remaining_options, @positional_parameters =
      nested_option_parser_control.argv.partition { |x| x.start_with? '-' }
    @options = evaluate(
      default_option_hash: nested_option_parser_control.default_option_hash,
      arguments:           @remaining_options,
      option_parser_proc:  nested_option_parser_control.option_parser_proc
    )

    # If this is a subcommand, remove the subcommand name from positional_parameters
    # and set @subcommand to the SubCmd instance.
    return unless @sub_cmds.any? && !@positional_parameters.empty?

    # Remove the first token, which might be the subcommand name, from positional parameters
    subcommand_name = @positional_parameters.shift
    subcommand = nested_option_parser_control.sub_cmds.find do |sub_cmd|
      sub_cmd.name == subcommand_name
    end
    unless subcommand
      @help&.call "No subcommand parsing was defined for '#{subcommand_name}'".red if help
      exit 1
    end

    @options = evaluate(
      arguments:           @remaining_options,
      default_option_hash: @options,
      option_parser_proc:  subcommand.option_parser_proc
    )
    return if @remaining_options.empty?

    @help&.call "Extra options provided (#{@remaining_options})"
    exit 1
  end

  # @return the command line arguments that were not matched by the option parser, ready for a subcommand parser.
  # This includes any positional parameters that were not matched by the option parser.
  #
  # @return [Array<String>] The remaining command line arguments after parsing.
  def argv
    @remaining_options + @positional_parameters
  end

  # Process the command line arguments and update the options hash.
  #
  # If option_parser_proc raises an `OptionParser::InvalidOption` exception,
  # it is caught and an error message is displayed before the program exits.
  # Otherwise, unmatched arguments are collectded in @remaining_options.
  #
  # @param default_option_hash [Hash] Default options to set before parsing.
  # @param arguments [Array<String>] The remaining command line arguments to parse.
  # @param option_parser_proc [Proc] The proc that defines the options for this parser.
  #
  # @yield [OptionParser, Proc] Yields the OptionParser instance and the option parser proc.
  # @yieldparam parser [OptionParser] The OptionParser instance to configure.
  #
  # @return [Hash] The options parsed from the command line arguments.
  def evaluate(default_option_hash:, arguments:, option_parser_proc:)
    options = default_option_hash
    option_parser = OptionParser.new(&option_parser_proc)
    option_parser.default_argv = arguments
    option_parser.order! arguments, into: options
    options
  rescue OptionParser::InvalidOption => e
    puts "Error: #{e.message}".red
    exit 1
  end
end
