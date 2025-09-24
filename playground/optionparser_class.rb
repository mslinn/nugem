require 'optparse'

class MyOptionParser
  attr_reader :parser, :options

  def initialize
    @options = {}
    @parser = OptionParser.new
    [dry_run_proc, out_dir_proc, verbose_proc].each do |p| # Build parser from option procs
      p.call(@parser, @options)
    end
  end

  # Proc for handling dry-run mode
  def dry_run_proc
    proc do |parser, opts|
      parser.on('-n', '--dry-run', 'Do everything except execute') do |value|
        opts[:dry_run] = value
      end
    end
  end

  # Build parser and apply all option procs
  def out_dir_proc
    proc do |parser, opts|
      parser.on('-o', '--out_dir=OUT_DIR') do |value|
        opts[:out_dir] = value
      end
    end
  end

  # Proc for handling verbosity
  def verbose_proc
    proc do |parser, opts|
      parser.on('-v', '--[no-]verbose', 'Run verbosely') do |value|
        opts[:verbose] = value
      end
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
