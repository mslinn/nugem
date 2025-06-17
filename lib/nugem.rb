require 'colorize'

def require_subdirectory(dir)
  Dir[File.join(dir, '*.rb')].each do |file|
    require file unless file == __FILE__
  end
end

require_subdirectory File.realpath(__dir__) # Require all Ruby files in 'lib/', except this file
require_subdirectory File.realpath('nugem', __dir__)

Signal.trap('INT') { exit }
