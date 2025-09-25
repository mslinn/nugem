def maybe_redirect_stdin
  input_from_env = ENV.fetch('nugem_argv', nil)
  return unless input_from_env

  require 'stringio'
  $stdin = StringIO.new(input_from_env)
  puts 'Reading STDIN from the nugem_argv environment variable.'
end

# Define the environment variable
ENV['nugem_argv'] = "Hello from Mars\nHello from Venus\nGoodbye\n"
maybe_redirect_stdin
# Now any code that reads from standard input (like gets) will read from ENV['nugem_argv'].

# Do not call $stdio.eof? to test EOF because it will block until the process exits
# if STDIN is a pipe or socket.
#
# Detect when STDIN reaches EOF by gets returning nil
while line = gets # rubocop:disable Lint/AssignmentInCondition
  puts line
end
