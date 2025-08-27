require 'optparse'

# Define a proc for each option or group of related options
#
# Each proc takes two parameters:
# - options: a Hash in which to store the option values
# - parser: the OptionParser object to which to add the options
#
# After all procs have been called, parser.parse! is called
# to parse the command line arguments and populate the options Hash

outdir_proc = proc do |options, parser|
  # options[:out_dir] = Dir.home # optional default value, not required if defined earlier
  parser.on('-o', '--out_dir=OUT_DIR') do |value|
    options[:out_dir] = value
  end
end

verbose_proc = proc do |options, parser|
  # options[:verbose] = nil # optional default value, not required if defined earlier
  parser.on('-v', '--verbose=VERBOSE') do |value|
    options[:verbose] = value
  end
end

parser = OptionParser.new
procs = [outdir_proc, verbose_proc] # Array of procs that obtain option values
options = { # Default values for all options can be defined here
  out_dir: Dir.home,
  verbose: nil,
}
procs.each { |p| p.call(options, parser) } # Set up accumulation of option values from each proc
# Actually do the parsing now
parser.parse!(['-o', '/tmp/test', '-v', 'very']) # Pass simulated command line arguments
puts options # {:out_dir=>"/tmp/test", :verbose=>"very"}
