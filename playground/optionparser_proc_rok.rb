require 'optparse'

# @return a lambda that retrieves a hash containing the value later
outdir_proc = proc do |parser|
  out_dir_holder = nil
  parser.on('-o', '--out_dir=OUT_DIR') do |value|
    out_dir_holder = value
  end
  -> { { out_dir: out_dir_holder } }
end

# @return a lambda that retrieves a hash containing the value later
verbose_proc = proc do |parser|
  verbose_holder = nil
  parser.on('-v', '--verbose=VERBOSE') do |value|
    verbose_holder = value
  end
  -> { { verbose: verbose_holder } }
end

parser = OptionParser.new
outdir_getter = outdir_proc.call(parser)
verbose_getter = verbose_proc.call(parser)
parser.parse!(['-o', '/tmp/test', '-v', 'very'])
result = outdir_getter.call
           .merge(verbose_getter.call)
           .merge({ x: 'y' })
puts result # {:out_dir=>"/tmp/test", :verbose=>"very", :x => "y"}
