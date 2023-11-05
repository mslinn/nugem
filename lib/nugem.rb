require 'thor'
require_relative 'util'

module Nugem
  # @return Path to the generated gem
  def self.dest_root(gem_name)
    File.expand_path "generated/#{gem_name}"
  end
end

require_relative 'nugem/git'
require_relative 'nugem/cli'
require_relative 'nugem/repository'
require_relative 'nugem/version'
