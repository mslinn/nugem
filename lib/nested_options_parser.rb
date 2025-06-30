require 'optparse'

class NestedOptionParser
  attr_reader :unmatched_args, :positional_parameters, :options, :remaining_argv

  # Initialize a NestedOptionParser instance.
  # To handle a subcommand, pass a block that yields the `NestedOptionParser` instance and a proc that parses the
  # options for the subcommand by calling `OptionParser.on`.
  # The subcommand parser procs can be defined in the `subcommand_parser_procs` parameter.
  #
  # @param default_argv [Array<String>] The command line arguments to parse.
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
    default_argv: ARGV,
    default_option_hash: {},
    sub_name: nil,
    subcommand_parser_procs: []
  )
    @sub_name = sub_name
    @subcommand_parser_procs = subcommand_parser_procs

    @remaining_argv, @positional_parameters = default_argv.partition { |x| x.start_with? '-' }

    if sub_name && subcommand_parser_procs.empty?
      puts "Warning: sub_name '#{@sub_name}' is set, but subcommand_parser_procs was provided. This may lead to unexpected behavior.".red
      exit 2
    end
    if sub_name.to_s.empty? && !subcommand_parser_procs.empty?
      puts "Warning: sub_name '#{@sub_name}' was not set, but subcommand_parser_procs is empty. This may lead to unexpected behavior.".red
      exit 3
    end
    @options = {} # Set default values here
    report 'Before processing'
    result = evaluate(default_option_hash, @remaining_argv, &option_parser_proc)
    report "After processing, result=#{result} (should be same as @options)"
  end

  def argv
    @remaining_argv + @positional_parameters
  end

  # This method processes the command line arguments and updates the options hash.
  # The method suppresses the OptionParser::InvalidOption Exception that OptionParser normally raises when an unknown option is encountered.
  # Instead, it collects the unmatched arguments in @remaining_argv.
  #
  # @param default_option_hash [Hash] Default options to set before parsing.
  # @param argv [Array<String>] The remaining command line arguments to parse.
  # @yield [OptionParser, Proc] Yields the OptionParser instance and the option parser proc.
  # @yieldparam parser [OptionParser] The OptionParser instance to configure.
  # @yieldparam op_proc [Proc] The proc that defines the options for this parser.
  # @return [Hash] The options parsed from the command line arguments.
  #
  # @return [Hash] The options hash after parsing.
  def evaluate(default_option_hash, default_argv, &op_proc)
    @options = default_option_hash
    @remaining_argv = OptionParser.new do |parser|
      parser.default_argv = default_argv
      parser.raise_unknown = false # if @subcommand_parser_procs
      yield parser, op_proc
    rescue OptionParser::InvalidOption => e
      @remaining_argv << e.args.first if e.args.any?
    end.order!(into: @options)
    @options
  rescue OptionParser::InvalidOption => e
    puts "Error: #{e.message}"
    exit 1
  end

  def report(msg)
    puts <<~END_MSG
      #{msg}:
        @unmatched_args=#{@unmatched_args}
        @options=#{@options}
        @remaining_argv=#{@remaining_argv}
        @positional_parameters=#{@positional_parameters}
    END_MSG
  end
end

# my_option_parser_proc = proc do |parser|
#   parser.on '-h', '--help'
#   parser.on '-o', '--out_dir OUT_DIR'
# end

# NestedOptionParser.new(
#   {},
#   my_option_parser_proc,
#   this_argv: %w[-h -x pos_param1 pos_param2 -y -z]
# )

# NestedOptionParser.new(
#   {},
#   my_option_parser_proc,
#   this_argv: %w[-a --blah -h -x pos_param1 pos_param2 -y -z]
# )
