def fun(**options)
  puts "fun options: #{options}"
  puts "fun options[:dry_run]: #{options[:dry_run]}"
  @dry_run = options.key?(:dry_run) ? options[:dry_run] : false
  puts "fun dry_run: #{dry_run}" # This line will raise an error because dry_run is not defined
rescue StandardError => e
  puts "Error in fun: #{e.message}"
end

my_options = { dry_run: true }
fun(**my_options)
puts "@dry_run: #{@dry_run}"
