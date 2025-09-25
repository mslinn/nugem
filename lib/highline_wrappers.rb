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

  def ask(template_or_question, answer_type = nil, &)
    if $stdin.tty? # highline handles terminal I/O
      highline_ask(template_or_question, answer_type, &)
    else
      read_from_pipe(template_or_question, answer_type, &)
    end
  end

  def read_from_pipe(prompt, answer_type, &)
    if prompt.end_with? ' '
      print prompt
    else
      puts prompt
    end
    q = HighLine::Question.new(prompt, answer_type, &)
    q.answer = $stdin.read
    puts q.answer
    return q.answer if q.answer == ''

    unless q.valid_answer?
      error_message = q.responses[:not_valid] ||
                      q.responses[:not_in_range] ||
                      'Validation failed.'
      puts "Input '#{q.answer}' is invalid: #{error_message}".red
      exit! 33
    end
    q.answer
  rescue StandardError => e
    puts e.message.red
    puts e.backtrace.join('\n').red
    exit! 35
  end
end
