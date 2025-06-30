require 'optparse'

class NestedOptionParser
  attr_reader :unmatched_args, :positional_parameters, :options, :remaining_argv

  # Initializes a NestedOptionParser instance.
  #
  # @param option_parser_proc [Proc] A proc that defines the options for this parser.
  # @param default_option_hash [Hash] Default options to be set before parsing.
  # @param sub_name [String] Name of the subcommand (if applicable).
  # @param subcommand_parser_procs [Array<Proc>] Procs for subcommand parsers.
  # @param argv [Array<String>] The command line arguments to parse.
  def initialize(option_parser_proc:, default_option_hash: {}, sub_name: nil, subcommand_parser_procs: [], argv: ARGV)
    @unmatched_args = []
    @subcommand_parser_procs = subcommand_parser_procs

    @positional_parameters, @remaining_argv = argv.partition { |x| x.start_with? '-' }

    @options = {} # Set default values here
    report 'Before processing'
    # @option_parser = evaluate option_parser_proc
    result = evaluate(default_option_hash, @remaining_argv, &option_parser_proc)
    report "After processing, result=#{result} (should be same as @options)"
  end

  def argv
    @unmatched_args + @positional_parameters
  end

  # Suppresses the Exception raised by OptionParser when an unknown option is encountered.
  # Instead, it collects the unmatched arguments in @unmatched_args.
  def evaluate(default_option_hash, argv, &op_proc)
    @options = default_option_hash
    @remaining_argv = OptionParser.new do |parser|
      parser.default_argv = argv
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
        ARGV=#{ARGV}"
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
#   argv: %w[-h -x pos_param1 pos_param2 -y -z]
# )

# NestedOptionParser.new(
#   {},
#   my_option_parser_proc,
#   argv: %w[-a --blah -h -x pos_param1 pos_param2 -y -z]
# )
