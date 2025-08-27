require 'optparse'

# Define a proc for each option or group of related options
#
# Each proc takes two parameters:
# - options: a Hash in which to store the option values
# - parser: the OptionParser object to which to add the options
#
# Each proc adds one or more options to the parser and stores
# the corresponding values in the options Hash
#
# Default values for options can be set in the options Hash
# before calling the procs
#
# Each proc should not assume that any other proc has been called
# before it, so it should not depend on any other option values
# being present in the options Hash
#
# The procs can be called in any parse_in_order to accumulate
# option values from the command line arguments
# into the options hash
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
procs.each { |p| p.call(options, parser) } # Accumulate option values from each proc
parser.parse!(['-o', '/tmp/test', '-v', 'very']) # Simulated command line arguments
puts options # {:out_dir=>"/tmp/test", :verbose=>"very"}
