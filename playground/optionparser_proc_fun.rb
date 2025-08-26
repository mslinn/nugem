require 'optparse'

argv = ['init', '-v', '-t', 'blah']
subcommand = argv.shift
if subcommand.nil?
  puts 'Error: No subcommand provided. Subcommands are: init and deploy'
  exit 1
end
options = { verbose: false } # Default value of options

common_proc = proc do |parser, opts|
  parser.on('-v', '--[no-]verbose', 'Run verbosely') do |value|
    opts[:verbose] = value
  end
end

subcommand_procs = {
  'init'   => proc do |parser, opts|
    parser.on('-t', '--template=TEMPLATE', 'Template to use') do |value|
      opts[:template] = value
    end
  end,
  'deploy' => proc do |parser, opts|
    parser.on('-e', '--env=ENV', 'Environment to deploy to') do |value|
      opts[:env] = value
    end
  end,
}

parser = OptionParser.new
common_proc.call(parser, options)

# Subcommand-specific options
if subcommand_procs.key?(subcommand)
  subcommand_procs[subcommand].call(parser, options)
else
  puts "Unknown subcommand: #{subcommand}"
  exit 1
end

parser.parse(argv) # Example args; replace with ARGV in real use
puts "Subcommand '#{subcommand}' has options #{options.inspect}"
