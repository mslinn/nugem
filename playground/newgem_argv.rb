def maybe_redirect_stdin
  input_from_env = ENV.fetch('nugem_argv', nil)
  return unless input_from_env

  require 'stringio'
  $stdin = StringIO.new(input_from_env)
  puts 'Reading STDIN from the nugem_argv environment variable.'
end

ENV['nugem_argv'] = "Hello from Mars\nHello from Venus\nGoodbye\n"
maybe_redirect_stdin

puts gets # => "Hello from Mars"
puts gets # => "Hello from Venus"
puts gets # => "Goodbye"
puts gets # => "" # EOF for STDIN yields nil, which prints as a newline
puts gets # => ""
puts gets # => ""
