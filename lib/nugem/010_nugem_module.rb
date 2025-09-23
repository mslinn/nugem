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
    options = parse_gem_type_name # Only sets the :gem_type and :gem_name
    options[:source_root] = File.expand_path('../../templates', File.dirname(__FILE__)) # templates live here
    nugem_options = case options[:gem_type] # Parse all remaining options based on :gemtype
                    when 'ruby'
                      Options.new options
                    when 'jekyll'
                      JekyllOptions.new options
                    else
                      puts "Unrecognized gem type '#{options[:gem_type]}'.".red
                      exit 2
                    end
    nop = nugem_options.nested_option_parser_from ARGV
    if nop.argv.any?
      puts "Invalid syntax: #{nop.argv}"
      exit 5
    end
    nugem_options.prepare_and_report.each_line { |line| print line.green }

    nugem = Nugem.new nugem_options.options
    nugem.create_scaffold
    nugem.initialize_repository
    puts nugem.todos_report if nugem_options.options[:todos]
    msg = `tree #{nugem_options.options[:output_directory]}`
    if msg.include? '0 directories, 0 files'
      puts 'No files were generated'.yellow
    else
      puts "\n"
      msg.each_line { |line| print line.green }
    end
  end

  def method_option(name, default: nil, desc: '', enum: [], type: :string)
    name = name.to_s

    msg = "Defining method #{name} returning #{type} with default value #{default}"
    msg += "\n  Description: #{desc}" unless desc.empty?
    msg += "\n  Enum values: #{enum.join(', ')}" unless enum.empty?
    puts msg.green

    define_method(name) do
      instance_variable_get("@#{name}")
    end

    define_method("#{name}=") do |value|
      instance_variable_set("@#{name}", value)
    end

    instance_variable_set("@#{name}", default)
    # TODO: figure out what to do with desc, enum and type
  end

  # Sets :gem_type and :gem_name values in options from the first two command line arguments.
  # Modifies ARGV by removing those values.
  # Ignores other command line arguments.
  # @return [Hash] Options parsed from the command line arguments
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
