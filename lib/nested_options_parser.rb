require 'optparse'

class NestedOptionParser
  def initialize(default_options, option_parser_proc, subcommand_parser_procs = [], argv: ARGV)
    @unmatched_args = []
    @subcommand_parser_procs = subcommand_parser_procs

    @positional_parameters, optional_parameters = argv.partition { |x| x.start_with? '-' }

    # Establish default values:
    @options = {}
    @remaining_argv = optional_parameters
    report 'Before processing'
    # @option_parser = evaluate option_parser_proc
    result = evaluate(default_options, argv, &option_parser_proc)
    report "After processing, result=#{result} (should be same as @options)"
  end

  def evaluate(default_options, argv, &op_proc)
    @options = default_options
    @remaining_argv = OptionParser.new do |parser|
      parser.default_argv = argv
      parser.raise_unknown = false
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

my_option_parser_proc = proc do |parser|
  parser.on '-h', '--help'
  parser.on '-o', '--out_dir OUT_DIR'
end

NestedOptionParser.new(
  {},
  my_option_parser_proc,
  argv: %w[-h -x pos_param1 pos_param2 -y -z]
)

NestedOptionParser.new(
  {},
  my_option_parser_proc,
  argv: %w[-a --blah -h -x pos_param1 pos_param2 -y -z]
)
