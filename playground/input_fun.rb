# See https://github.com/JEG2/highline#:~:text=inject/import%20HighLine%20methods%20on%20Kernel
require 'highline/import'

value = if $stdin.tty?
          ask 'Gimme a value, honey: '
        else
          $stdin.read # from pipe
        end

puts "Got #{value}"
