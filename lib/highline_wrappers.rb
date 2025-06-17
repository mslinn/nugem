require 'highline/import'

module HighlineWrappers
  def yes_no?(prompt = 'Continue?', default: true)
    a = ''
    s = default ? '[Y/n]' : '[y/N]'
    d = default ? 'y' : 'n'
    until %w[y n].include? a # rubocop:disable Performance/CollectionLiteralInLoop
      a = ask("#{prompt} #{s} ") do |q|
        q.limit = 1
        q.case = :downcase
      end
      a = d if a.empty?
    end
    a == 'y'
  end

  # Invokes yes_no? with the default answer being 'no'
  def no?(prompt = 'Continue?')
    yes_no? prompt, default: false
  end

  # Invokes yes_no? with the default answer being 'yes'
  def yes?(prompt = 'Continue?')
    yes_no? prompt, default: true
  end
end
