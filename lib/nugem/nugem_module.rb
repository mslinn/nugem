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

  # Sets :gem_type and :gem_name values in options from the command line arguments.
  # Ignores other command line arguments.
  # @return [Hash] Options parsed from the command line arguments
  def self.parse_positional_parameters
    pp = ::Nugem.positional_parameters
    ::Nugem.help if pp.empty? || pp.length < 2
    ::Nugem.help("The type and name of the #{@ptions[:gem_type]} to create was not specfied.", errors_are_fatal: @errors_are_fatal) if pp.empty?
    ::Nugem.help('Invalid syntax.', errors_are_fatal: @errors_are_fatal) if pp.length > 2

    options = {}
    options[:gem_type] = pp[0]
    options[:gem_name] = pp[1]

    ::Nugem.help("Invalid #{options[:gem_type]} name.", errors_are_fatal: @errors_are_fatal) unless ::Nugem.validate_gem_name(options[:gem_name])

    options
  end

  def self.positional_parameters
    ARGV.reject { |x| x.start_with? '-' }
  end

  # TODO: consolidate with template_directory
  # @return Path to the templates
  def self.source_root
    File.expand_path '../../templates', __dir__
  end

  def self.run_me
    parsed_options = @nugem_options.parse_options
    @options = parse_positional_parameters # Only sets the gem_type and gem_name
    case @options[:gem_type] # Parse all remaining options based on the gem type
    when 'gem'
      @nugem_options = Options.new(@options)
    when 'jekyll'
      @nugem_options = JekyllOptions.new(@options)
    else
      puts "Error: unrecognized gem type '#{@options['gem_type']}'."
      exit 2
    end
    parsed_options = @nugem_options.parse_options
    @nugem = Nugem.new parsed_options
    puts @nugem_options.act.green
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

  def count_todos(filename)
    filename_fq = "#{@options[:out_dir]}/#{filename}"
    content = File.read filename_fq
    content.scan('TODO').length
  end

  def initialize_repository(gem_name)
    Dir.chdir @options[:out_dir] do
      # puts set_color("Working in #{Dir.pwd}", :green)
      run 'chmod +x bin/*'
      run 'chmod +x exe/*' if @executables
      create_local_git_repository
      FileUtils.rm_f 'Gemfile.lock'
      # puts set_color("Running 'bundle'", :green)
      # run 'bundle', abort_on_failure: false
      create_repo = @yes || begin
        yes? "Do you want to create a repository on #{@repository.host.camel_case} named #{gem_name}? (y/N)".green
      end
      create_remote_git_repository @repository if create_repo
    end
    puts set_color("The #{gem_name} gem was successfully created.", :green)
    puts set_color('Remember to run bin/setup in the new gem directory', :green)
    report_todos gem_name
  end

  def report_todos(gem_name)
    gemspec_todos = count_todos "#{gem_name}.gemspec"
    readme_todos = count_todos 'README.md'
    if readme_todos.zero? && gemspec_todos.zero?
      puts set_color("There are no TODOs. You can run 'bundle' from within your new gem project now.", :blue)
      return
    end

    msg = 'Please complete'
    msg << " the #{gemspec_todos} TODOs in #{gem_name}.gemspec" if gemspec_todos.positive?
    msg << ' and' if gemspec_todos.positive? && readme_todos.positive?
    msg << " the #{readme_todos} TODOs in README.md." if readme_todos.positive?
    puts set_color(msg, :yellow)
  end
end
