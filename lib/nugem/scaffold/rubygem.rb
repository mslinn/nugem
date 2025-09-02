require 'optparse'

module Nugem
  class Cli
    desc 'ruby NAME', 'Creates a new gem scaffold.'

    long_desc <<~END_DESC
      Creates a new Ruby gem scaffold with the given NAME,
      by default hosted by GitHub and published on RubyGems.
    END_DESC

    method_option :host, type: :string, default: 'github',
      enum: %w[bitbucket github gitlab], desc: 'Repository host.'

    method_option :private, type: :boolean, default: false,
      desc: 'Publish the gem in a private repository.'

    def gem(gem_name)
      # puts "gem_name=#{gem_name}".yellow
      super if gem_name.empty?

      @executables = options[:executable]
      @force       = options[:force]
      @host        = options[:host] # FIXME: conflicts with @host in create_gem_scaffold()
      @out_dir     = options[:out_dir]
      @private     = options[:private]

      create_plain_scaffold gem_name
      initialize_repository gem_name
    end

    private

    # Defines globals for templates
    # TODO: Support GitLab
    def create_plain_scaffold(gem_name)
      @gem_name = gem_name
      @class_name = Nugem.camel_case @gem_name
      @module_name = "#{@class_name}Module"
      @host       = options[:bitbucket] ? :bitbucket : :github # FIXME: conflicts with @host in gem()
      @repository = Nugem::Repository.new(
        host:    @host,
        name:    @gem_name,
        private: @private,
        user:    git_repository_user_name(@host)
      )
      puts "Creating a scaffold for a new Ruby gem named #{@gem_name} in #{@out_dir}.".green
      directory 'common/gem_scaffold',        @out_dir, exclude_pattern: /spec.*/
      directory 'common/executable_scaffold', @out_dir if @executables
      template  'common/LICENCE.txt',         "#{@out_dir}/LICENCE.txt"
    end
  end
end
