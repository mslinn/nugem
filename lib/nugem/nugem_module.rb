require 'colorized_string'
require 'fileutils'
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

  # @return Path to the generated gem
  def self.dest_root(out_dir, gem_name)
    File.expand_path "#{out_dir}/#{gem_name}"
  end

  #
  # Instance methods
  #

  def count_todos(filename)
    filename_fq = "#{Nugem.dest_root @out_dir, gem_name}/#{filename}"
    content = File.read filename_fq
    content.scan('TODO').length
  end

  def initialize_repository(gem_name)
    Dir.chdir Nugem.dest_root(@out_dir, gem_name) do
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

  def self.positional_parameters
    ARGV.reject { |x| x.start_with? '-' }
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

  def self.run_me
    pp = ::Nugem.positional_parameters
    ::Nugem.help if pp.empty?
    gem_type = pp.first
    case gem_type
    when 'gem'
      nugem = Options.new
    when 'jekyll'
      nugem = JekyllOptions.new
    else
      puts "Error: unrecognized gem type '#{gem_type}'."
      exit 2
    end
    nugem.parse_options
    puts nugem.act.green
  end

  def self.todo
    'TODO: ' if @todos
  end

  # TODO: consolidate with template_directory
  # @return Path to the templates
  def self.source_root
    File.expand_path '../../templates', __dir__
  end

  # TODO: consolidate with source_root
  # @return Path to the templates
  def self.template_directory
    File.join gem_path(__FILE__), 'templates'
  end
end
