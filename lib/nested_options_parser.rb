require 'optparse'

SubCmd = Struct.new(:name, :parser_proc)

class NestedOptionParser
  attr_reader :option_parser_proc, :options, :positional_parameters, :remaining_options, :sub_cmds

  # Initialize a NestedOptionParser instance.
  # To handle a subcommand, pass a block that yields the `NestedOptionParser` instance and a proc that parses the
  # options for the subcommand by calling `OptionParser.on`.
  # The subcommand parser procs can be defined in the `subcommand_parser_procs` parameter.
  #
  # @param argv [Array<String>] The command line arguments to parse.
  # @param option_parser_proc [Proc] A proc that parses the options for a command by calling `OptionParser.on` and
  # similar methods at least once.
  # @param default_option_hash [Hash] Default options to be set before parsing.
  # @param sub_name [String] Name of the subcommand (if applicable). The top-level command does not have a sub_name.
  #   For example, if you have a command `myapp mysubcommand`, then `sub_name` would be `mysubcommand`.
  # @param subcommand_parser_procs [Array<Proc>] Procs for subcommand parser(s). The array is processed in order.
  #   Each proc should yield an `OptionParser` instance and a proc that defines the options for that subcommand.
  #   If no subcommands are defined, this can be an empty array.
  #
  # @example
  #   NestedOptionParser.new(
  #     argv: %w[-h -x pos_param1 pos_param2 -y -z]
  #     default_option_hash: { help: false },
  #     option_parser_proc: option_parser_proc: proc do |parser|
  #       parser.on '-h', '--help'
  #       parser.on '-o', '--out_dir OUT_DIR'
  #     end,
  #     sub_name: 'mysubcommand',
  #     subcommand_parser_procs: [my_subcommand_parser_proc],
  #   )
  def initialize(
    option_parser_proc:,
    argv: ARGV,
    default_option_hash: {},
    sub_cmds: []
  )
    @option_parser_proc = option_parser_proc
    @sub_cmds = sub_cmds

    @remaining_options, @positional_parameters = argv.partition { |x| x.start_with? '-' }

    # report "\nBefore processing"
    @options = evaluate(
      default_option_hash: default_option_hash,
      arguments:           @remaining_options,
      option_parser_proc:  option_parser_proc
    )
    # report "After evaluating main command, @options=#{@options}"

    # If this is a subcommand, remove the subcommand name from positional_parameters and
    # set @subcommand to the SubCmd instance.
    return unless @sub_cmds.any? && @positional_parameters && @sub_cmds.include?(@positional_parameters.first)

    # Remove the subcommand name from positional parameters
    subcommand_name = @positional_parameters.shift
    subcommand = sub_cmds.find { |sub_cmd| sub_cmd.name == subcommand_name }
    unless subcommand
      puts "No subcommand parsing defined for '#{subcommand_name}'".red
      exit 1 # TODO: call help
    end

    @options = evaluate(
      arguments:           @remaining_options,
      default_option_hash: @options,
      option_parser_proc:  subcommand.parser_proc
    )
    # report "After evaluating subcommand #{subcommand.name}, @options=#{@options}"
    return if @remaining_options.empty?

    puts "Extra options provided (#{@remaining_options})"
    exit 1 # TODO: call help
  end

  # Returns the command line arguments that were not matched by the option parser, ready for a subcommand parser.
  # This includes any positional parameters that were not matched by the option parser.
  #
  # @return [Array<String>] The remaining command line arguments after parsing.
  def argv
    @remaining_options + @positional_parameters
  end

  # This method processes the command line arguments and updates the options hash.
  # The method suppresses the OptionParser::InvalidOption Exception that OptionParser normally raises
  # when an unknown option is encountered.
  # Instead, it collects the unmatched arguments in @remaining_options.
  #
  # @param default_option_hash [Hash] Default options to set before parsing.
  # @param argv [Array<String>] The remaining command line arguments to parse.
  # @yield [OptionParser, Proc] Yields the OptionParser instance and the option parser proc.
  # @yieldparam parser [OptionParser] The OptionParser instance to configure.
  # @yieldparam option_parser_proc [Proc] The proc that defines the options for this parser.
  # @return [Hash] The options parsed from the command line arguments.
  #
  # @return [Hash] The options hash after parsing.
  def evaluate(default_option_hash:, arguments:, option_parser_proc:)
    options = default_option_hash
    option_parser = OptionParser.new(&option_parser_proc)
    option_parser.order! arguments, into: options
    options
  rescue OptionParser::InvalidOption => e
    puts "Error: #{e.message}"
    exit 1
  end

  # Just for debugging
  def report(msg)
    puts <<~END_MSG
      #{msg}:
        @options=#{@options}
        @remaining_options=#{@remaining_options}
        @positional_parameters=#{@positional_parameters}
    END_MSG
  end
end
