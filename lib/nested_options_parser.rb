require 'optparse'

class NestedOptionParser
  def initialize(default_options, option_parser_proc, subcommand_parser_procs = [], argv: ARGV)
    @unmatched_args = []
    # @option_parser = evaluate option_parser_proc
    @subcommand_parser_procs = subcommand_parser_procs
    evaluate(default_options, argv, &option_parser_proc)
    puts "ARGV=#{ARGV}"
    puts "@unmatched_args=#{@unmatched_args}"
  end

  # How to add this to every option_parser_proc:
  # parser.on /.*/ { |subcommand| subcommand.call } # Somehow the modified ARGV from the subcommand
  # needs to affect the caller's ARGV

  def evaluate(default_options, argv, &op_proc)
    options = default_options
    OptionParser.new do |parser|
      parser.default_argv = argv
      parser.raise_unknown = false
      yield parser, op_proc
      parser.on(/.*/) do |arg|
        puts "Unmatched: #{arg}"
        @unmatched_args << arg
      end
    end.order! into: options
    puts "After parsing, options=#{options}"
    options
  rescue OptionParser::InvalidOption => e
    puts e.message
    exit 1
  end
end


my_option_parser_proc = proc do |parser|
  puts "Evaluating my_option_parser_proc"
  parser.on '-h', '--help'
  parser.on '-o', '--out_dir OUT_DIR'
end

NestedOptionParser.new({}, my_option_parser_proc, argv: %w[-h -x])
