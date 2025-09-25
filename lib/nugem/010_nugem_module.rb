require 'colorized_string'
require 'fileutils'
require 'rubygems/specification'
require 'rugged'

# Class methods
module Nugem
  def self.camel_case(str)
    str.tr('-', '_')
      .split('_')
      .map(&:capitalize)
      .join
  end

  # Entry point
  def self.main
    initial_options = parse_gem_type_name # Only sets the :gem_type and :gem_name
    initial_options[:source_root] = File.expand_path('../../templates', File.dirname(__FILE__)) # templates live here
    unless File.exist?(initial_options[:source_root]) && !Dir.empty?(initial_options[:source_root])
      puts "Error: The templates directory '#{initial_options[:source_root]}' does not exist or is empty.".red
      exit! 2
    end
    options = case initial_options[:gem_type] # Parse all remaining options based on options[:gemtype]
              when 'ruby'
                RubyOptions.new initial_options
              when 'jekyll'
                JekyllOptions.new initial_options
              else
                puts "Error: Unrecognized gem type '#{initial_options[:gem_type]}'.".red
                exit! 2
              end

    nop = options.nested_option_parser_from ARGV
    if nop.argv.any?
      puts "Invalid syntax: #{nop.argv}".red
      exit! 5
    end

    options.prepare_and_report.each_line { |line| print line.green }

    nugem = Nugem.new options.options # Computes nugem.options[:output_directory]
    nugem.cb.add_object_to_binding_as('@jekyll', true) if initial_options[:gem_type] == 'jekyll'
    nugem.generate_ruby_scaffold
    nugem.generate_jekyll_scaffold if initial_options[:gem_type] == 'jekyll'
    nugem.initialize_repository

    puts nugem.todos_report if options.options[:todos]
    msg = `tree #{options.options[:output_directory]}`
    if msg.include? '0 directories, 0 files'
      puts 'No files were generated'.yellow
    else
      puts "\n"
      msg.each_line { |line| print line.green }
    end
  end

  # Sets :gem_type and :gem_name values in options from the first two command line arguments.
  # Modifies ARGV by removing those values.
  # Ignores other command line arguments.
  # @return [Hash] RubyOptions parsed from the command line arguments
  def self.parse_gem_type_name
    ::Nugem.help_proc.call nil, errors_are_fatal: true if ARGV.empty? || ARGV[0] == '-h' || ARGV[0] == '--help'

    if ARGV.length < 2 || ARGV[0..1].any? { |x| x.start_with? '-' } # This comment prevents folding
      ::Nugem.help_proc.call 'The type and name of the gem to create must be specfied before any options.',
                             errors_are_fatal: true
    end

    options = {}
    options[:gem_type] = ARGV[0]
    options[:gem_name] = ARGV[1]

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
end
