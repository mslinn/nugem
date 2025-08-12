require 'yaml'

require_relative '../highline_wrappers'

module Nugem
  class Nugem
    include HighlineWrappers

    def gem_server_url
      'https://rubygems.org'
    end
  end
end
