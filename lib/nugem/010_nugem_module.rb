require 'colorized_string'
require 'fileutils'
require 'rubygems/specification'
require 'rugged'

module Nugem
  #
  # Class methods
  #

  def self.camel_case(str)
    str.tr('-', '_')
      .split('_')
      .map(&:capitalize)
      .join
  end

  # Sets :gem_type and :gem_name values in options from the first two command line arguments.
  # Modifies ARGV by removing those values.
  # Ignores other command line arguments.
  # @return [Hash] Options parsed from the command line arguments
  def self.parse_gem_type_name
    ::Nugem.help_proc.call nil, errors_are_fatal: true if ARGV.empty?

    if ARGV.length < 2 || ARGV[0..1].any { |x| x.start_with? '-' } # This comment prevents folding
      ::Nugem.help_proc.call 'The type and name of the gem to create must be specfied before any options.',
                             errors_are_fatal: true
    end

    options = {}
    options[:gem_type] = ARGV.shift
    options[:gem_name] = ARGV.shift

    unless ::Nugem.validate_gem_name(options[:gem_name]) # This comment prevents folding
      ::Nugem.help_proc.call "Error: '#{options[:gem_name]}' is an invalid gem name.",
                             errors_are_fatal: @errors_are_fatal
    end

    options
  end

  # TODO: consolidate with template_directory
  # @return Path to the templates
  def self.source_root
    File.expand_path '../../templates', __dir__
  end

  # Entry point
  def self.main
    options = parse_gem_type_name # Only sets the :gem_type and :gem_name
    nugem_options = case options[:gem_type] # Parse all remaining options based on :gemtype
                    when 'ruby'
                      Options.new options
                    when 'jekyll'
                      JekyllOptions.new options
                    else
                      puts "Unrecognized gem type '#{options[:gem_type]}'.".red
                      exit 2
                    end
    parsed_options = nugem_options.parse_options({})
    _nugem = Nugem.new parsed_options
    puts nugem_options.prepare_and_report.green
  end

  def self.todo
    'TODO: ' if @todos
  end

  # TODO: consolidate with source_root
  # @return Path to the templates
  def self.template_directory
    File.join gem_path(__FILE__), 'templates'
  end

  # Temporarily creates a bogus gem to validate the gem name.
  def self.validate_gem_name(name)
    spec = Gem::Specification.new do |s|
      s.authors               = ['Fred Flintstone']
      s.email                 = ['fred@flintstone.com']
      s.files                 = Dir[
                                  '{exe,lib,spec,templates}/**/*',
                                  '*.gemspec',
                                  '*.md'
                                ]
      s.homepage              = 'https://www.mslinn.com/ruby/6800-nugem.html'
      s.license               = 'MIT'
      s.name                  = name
      s.platform              = Gem::Platform::RUBY
      s.required_ruby_version = '>= 3.1.0'
      s.summary               = 'bogus summary'
      s.version               = '0.1.0'
    end

    begin
      spec.validate
      true
    rescue Gem::InvalidSpecificationException => e
      puts "Error: #{e.message} is an invalid gem name.".red
      false
    end
  end

  #
  # Instance methods
  #

  def todos_count(filename)
    filename_fq = "#{@options[:out_dir]}/#{filename}"
    content = File.read filename_fq
    content.scan('TODO').length
  end

  def todos_report(gem_name)
    gemspec_todos = todos_count "#{gem_name}.gemspec"
    readme_todos = todos_count 'README.md'
    if readme_todos.zero? && gemspec_todos.zero?
      puts "There are no TODOs. You can run 'bundle' from within your new gem project now.".blue
      return
    end

    msg = 'Please complete'
    msg << " the #{gemspec_todos} TODOs in #{gem_name}.gemspec" if gemspec_todos.positive?
    msg << ' and' if gemspec_todos.positive? && readme_todos.positive?
    msg << " the #{readme_todos} TODOs in README.md." if readme_todos.positive?
    puts msg.yellow
  end
end
