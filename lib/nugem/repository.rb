# Nugem::Repository contains informations about the git repository and the git user
module Nugem
  class Repository
    attr_reader :gem_server_url, :global_config, :host, :name, :out_dir, :private, :user, :user_name, :user_email

    Host = Struct.new(:domain, :camel_case, :id, keyword_init: true)
    HOSTS = [
      Host.new(domain: 'github.com',    camel_case: 'GitHub',    id: :github),
      Host.new(domain: 'gitlab.com',    camel_case: 'GitLab',    id: :gitlab),
      Host.new(domain: 'bitbucket.org', camel_case: 'BitBucket', id: :bitbucket),
    ].freeze

    def initialize(options)
      @name    = options[:name]
      @private = options[:private]
      @user    = options[:user]

      specified_host_id = (options[:host] || Hosts.first.id).to_sym

      @host = HOSTS.find { |host| host.id == specified_host_id }
      if @host.nil?
        abort <<~END_MSG
          No host with id #{specified_host_id} is known.
          Available hosts are: #{HOSTS.map(&:id.to_s).join(', ')}.
          If no host is specified, Nugem will use GitHub by default.
          For example, to use GitLab, run the command with --host gitlab.
        END_MSG
      end

      @gem_server_url = @host[:domain]

      @global_config = Rugged::Config.global
      if @global_config.nil?
        abort <<~END_MSG
          Error: No Git user has been configured yet.
          Please run the following commands to set up your Git user, then retry the command:
            git config --global user.name "Your Name"
            git config --global user.email "your.email@example.com"
        END_MSG
      end

      @user_email = @global_config['user.email']
      if @user_name.nil?
        abort <<~END_MSG
          Error: No Git user name has been configured yet.
          Please run the following to set up your Git user name, then retry the command:
            git config --global user.name "Your Name"
        END_MSG
      end

      @user_name = @global_config['user.name']
      return unless @user_name.nil?

      abort <<~END_MSG
        Error: No Git user email has been configured yet.
        Please run the following to set up your Git user email, then retry the command:
          git config --global user.email "your.email@example.com"
      END_MSG
    end

    def bitbucket?
      @host.id == :bitbucket
    end

    def github?
      @host.id == :github
    end

    def gitlab?
      @host.id == :gitlab
    end

    def origin
      "git@#{@host.domain}:#{@user}/#{@name}.git"
    end

    # TODO: Currently all private repositories are on BitBucket and all public repos are on GitHub
    # TODO: Drop BitBucket?
    # TODO: Support private repos on GitHub
    # TODO: Support GitLab
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
