# See https://github.com/JEG2/highline#:~:text=inject/import%20HighLine%20methods%20on%20Kernel
require 'highline/import'

module HighlineWrappers
  def yes_no?(prompt = 'More?', default_value: true)
    answer_letter = ''
    suffix = default_value ? '[Y/n]' : '[y/N]'
    default_letter = default_value ? 'y' : 'n'
    acceptable_responses = %w[y n]
    until acceptable_responses.include? answer_letter
      if $stdin.tty? # Read from terminal
        answer_letter = ask("#{prompt} #{suffix} ") do |q|
          q.limit = 1
          q.case = :downcase
        end
      else
        $stdin.read # from pipe
      end
      answer_letter = default_letter if answer_letter.empty?
    end
    answer_letter == 'y'
  end

  # Invokes yes_no? with the default answer being 'no'
  def no?(prompt = 'More?')
    yes_no? prompt, default: false
  end

  # Invokes yes_no? with the default answer being 'yes'
  def yes?(prompt = 'More?')
    yes_no? prompt, default: true
  end
end

class HighLine
  alias highline_ask ask

  def ask(template_or_question, answer_type = nil, &details)
    if $stdin.tty? # highline handles terminal I/O
      highline_ask(template_or_question, answer_type, &details)
    else # reading from pipe
      if template_or_question.end_with? ' '
        print template_or_question
      else
        puts template_or_question
      end
      # $stdout.flush
      yield details.block.call
      response = $stdin.read
      puts response
      response
    end
  end
end
