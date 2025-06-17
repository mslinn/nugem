# See https://github.com/JEG2/highline#:~:text=inject/import%20HighLine%20methods%20on%20Kernel
require 'highline/import'

module HighlineWrappers
  def yes_no?(prompt = 'More?', default_value: true)
    answer_letter = ''
    suffix = default_value ? '[Y/n]' : '[y/N]'
    default_letter = default_value ? 'y' : 'n'
    until %w[y n].include? answer_letter # rubocop:disable Performance/CollectionLiteralInLoop
      answer_letter = ask("#{prompt} #{suffix} ") do |q|
        q.limit = 1
        q.case = :downcase
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
