require 'colorizer'
require 'highline'
require_relative 'util'

Signal.trap('INT') { exit }

module Nugem
  # @return Path to the generated gem
  def self.dest_root(out_dir, gem_name)
    File.expand_path "#{out_dir}/#{gem_name}"
  end
end

require_relative 'nugem/git'
require_relative 'nugem/cli'
require_relative 'nugem/repository'
require_relative 'nugem/version'
