# Nugem::Repository contains informations about the git repository and the git user
module Nugem
  class Repository
    include HighlineWrappers

    attr_accessor :global_config, :host, :name, :out_dir, :private, :user, :user_name, :user_email

    Host = Struct.new(:domain, :camel_case, :id, keyword_init: true)
    HOSTS = [
      Host.new(domain: 'github.com',    camel_case: 'GitHub',    id: :github),
      Host.new(domain: 'gitlab.com',    camel_case: 'GitLab',    id: :gitlab),
      Host.new(domain: 'bitbucket.org', camel_case: 'BitBucket', id: :bitbucket),
    ].freeze

    def self.git_repository_user_name(host)
      global_config = Rugged::Config.global # TODO: does this set the accessor value?
      git_config_key = "nugem.#{host}user"
      user = global_config[git_config_key]

      # TODO: support BitBucket and GitLab
      gh_config = github_config
      user ||= gh_config&.dig('github.com', 'user')

      user_name = ask "What is your #{host} user name?" if user.to_s.empty?
      global_config[git_config_key] = user_name if user_name != global_config[git_config_key]
      user_name
    end

    def initialize(options)
      @name    = options[:name]
      @private = options[:private]
      @user    = options[:user]

      specified_host_id = (options[:host] || Hosts.first.id).to_sym

      @host = HOSTS.find { |host| host.id == specified_host_id }
      if @host.nil?
        abort <<~END_MSG.red
          No host with id #{specified_host_id} is known.
          Available hosts are: #{HOSTS.map(&:id.to_s).join(', ')}.
          If no host is specified, Nugem will use GitHub by default.
          For example, to use GitLab, run the command with --host gitlab.
        END_MSG
      end

      @global_config = Rugged::Config.global
      if @global_config.nil?
        abort <<~END_MSG.red
          Error: No Git user has been configured yet.
          Please run the following commands to set up your Git user, then retry the command:
            git config --global user.name "Your Name"
            git config --global user.email "your.email@example.com"
        END_MSG
      end

      @user_email = @global_config['user.email']
      if @user_email.nil?
        abort <<~END_MSG.red
          Error: No Git user email has been configured yet.
          Please run the following to set up your Git user email, then retry the command:
            git config --global user.email "your.email@example.com"
        END_MSG
      end

      @user_name = @global_config['user.name']
      return unless @user_name.nil?

      abort <<~END_MSG.red
        Error: No Git user name has been configured yet.
        Please run the following to set up your Git user name, then retry the command:
          git config --global user.name "Your Name"
      END_MSG
    end

    def bitbucket?
      @host.id == :bitbucket
    end

    def create_local_git_repository
      puts 'Creating the local git repository'.green
      run 'git init'
      run 'git add .'

      # See https://github.com/rails/thor/blob/v1.2.2/lib/thor/actions.rb#L236-L278
      run "git commit -aqm 'Initial commit'", abort_on_failure: false
    end

    # TODO: support GitLab
    def create_remote_git_repository
      puts "Creating a remote #{@host} repository".green
      if github?
        gh_config = github_config
        token = gh_config&.dig('github.com', 'oauth_token')

        token ||= ask('What is your Github personal access token', echo: false)
        curl_command = <<~END_CURL
          curl --request POST \
            --user '#{@host.user}:#{token}' \
            https://api.github.com/user/repos \
            -d '{"name":"#{@host.name}", "private":#{@host.private?}}'
        END_CURL
        run(curl_command, capture: true)
      elsif bitbucket?
        password = ask('Please enter your Bitbucket password', echo: false)
        fork_policy = @host.public? ? 'allow_forks' : 'no_public_forks'
        run <<~END_BITBUCKET
          curl --request POST \
            --user #{@host.user}:#{password} \
            https://api.bitbucket.org/2.0/repositories/#{@host.user}/#{@host.name} \
            -d '{"scm":"git", "fork_policy":"#{fork_policy}", "is_private":"#{repository.private?}"}'
        END_BITBUCKET
      else
        abort "Support for #{@host.id} has not been implemented yet."
      end
      run "git remote add origin #{@host.origin}"
      puts "Pushing initial commit to remote #{@host.host} repository".green
      run 'git push -u origin master'
    end

    def github?
      @host.id == :github
    end

    def github_config
      gh_hosts_file = "#{Dir.home}/.config/gh/hosts.yml"
      return nil unless File.exist? gh_hosts_file

      YAML.safe_load_file(gh_hosts_file)
    end

    def gitlab?
      @host.id == :gitlab
    end

    def initialize_repository(gem_name)
      Dir.chdir @options[:out_dir] do
        puts "Preparing a git repository in #{Dir.pwd}".green
        run 'chmod +x bin/*'
        run 'chmod +x exe/*' if @options[:executables].any?
        create_local_git_repository
        FileUtils.rm_f 'Gemfile.lock'
        # puts "Running 'bundle'".green
        # run 'bundle', abort_on_failure: false
        create_repo = begin
          hostcc = @repository.host.camel_case
          yes? "Do you want to create a repository on #{hostcc} named #{gem_name}? (y/N)".green
        end
        create_remote_git_repository @repository if create_repo
      end
      puts "The #{gem_name} gem was created.".green
      puts 'Remember to run bin/setup in the new gem directory'.yellow
      todos_report gem_name
    end

    def origin
      "git@#{@host.domain}:#{@user}/#{@name}.git"
    end

    def private?
      @private
    end

    def public?
      !@private
    end

    def url
      "https://#{@host.domain}/#{@user}/#{@name}"
    end
  end
end
