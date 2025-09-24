require 'optparse'

class MyOptionParser
  attr_reader :parser, :options

  def initialize
    @options = {}
    @parser = OptionParser.new
    @parser.on('-o', '--out-dir=OUT_DIR', 'Output directory') do |value|
      @options[:out_dir] = value
    end
  end

  def parse(argv = ARGV)
    @parser.parse! argv
  end
end

my_option_parser = MyOptionParser.new

argv = ['-o', '/tmp/blah'] # Simulate ARGV
puts "Parsing #{argv}"
unparsed_options = my_option_parser.parse argv
puts "Parsed options: #{my_option_parser.options}"
puts "Unparsed options: #{unparsed_options}"

argv = ['-o', '/tmp/blah', 'x'] # Simulate ARGV
puts "\nParsing #{argv}"
unparsed_options = my_option_parser.parse argv
puts "Parsed options: #{my_option_parser.options}"
puts "Unparsed options: #{unparsed_options}"
