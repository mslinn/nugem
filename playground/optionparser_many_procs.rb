require 'optparse'

# Define default values and accumulate option values into this Hash.
# The procs that follow are invoked such that option values
# accumulate into this variable.
options = {
  dry_run: false,
  out_dir: Dir.home,
  verbose: false,
}

# Proc for handling output directory
out_dir_proc = proc do |parser, opts|
  parser.on('-o', '--out_dir=OUT_DIR', 'Output directory') do |value|
    opts[:out_dir] = value
  end
end

# Proc for handling verbosity
verbose_proc = proc do |parser, opts|
  parser.on('-v', '--[no-]verbose', 'Run verbosely') do |value|
    opts[:verbose] = value
  end
end

# Proc for handling dry-run mode
dry_run_proc = proc do |parser, opts|
  parser.on('-n', '--dry-run', 'Do everything except execute') do |value|
    opts[:dry_run] = value
  end
end

# Build parser and apply all option procs
parser = OptionParser.new
[out_dir_proc, verbose_proc, dry_run_proc].each do |p|
  p.call(parser, options)
end

parser.parse!(['-o', '/tmp/test', '-v', 'very']) # Simulated command line arguments

puts "RubyOptions hash: #{options.sort.to_h}"
#   RubyOptions hash: {:dry_run=> false, :out_dir=>"/tmp/test", :verbose=>true}
