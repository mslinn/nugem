require 'custom_binding'
require 'rainbow/refinement'
require_relative 'highline_wrappers'

using Rainbow

# Loads files in alphabetical order
def require_subdirectory(dir)
  Dir[File.join(dir, '*.rb')].each do |file|
    # puts "Requiring #{file}".blue
    require_relative file unless file == __FILE__
  end
end

require_subdirectory File.realpath(__dir__) # Require all Ruby files in 'lib/', except this file
require_subdirectory File.realpath('nugem', __dir__)
require_subdirectory File.realpath('nugem/scaffold', __dir__)

Signal.trap('INT') { exit!(-1) }

HighlineWrappers.maybe_redirect_stdin
