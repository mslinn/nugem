require 'fileutils'
require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class JekyllOptionsTest
  TEST_OUT_DIR = File.join(Dir.tmpdir, 'nugem_test').freeze
end
