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
      @host = HOSTS.find { |host| host.id == options[:host] }
      @private = options[:private]
      @name    = options[:name]
      @user    = options[:user]

      @global_config = Rugged::Config.global
      abort 'Git global config not found' if @global_config.nil?

      @user_name  = @global_config['user.name']
      @user_email = @global_config['user.email']
      @gem_server_url = options[:gem_server_url]
      @private = options[:private]
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
