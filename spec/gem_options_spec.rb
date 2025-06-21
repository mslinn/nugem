require 'fileutils'
require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class GemOptionsTest
  TEST_DIR = File.join(Dir.tmpdir, 'nugem/test').freeze
  ARGV.clear
  ARGV = '-L debug gem' # rubocop:disable Style/MutableConstant

  RSpec.describe ::Nugem::Options do
    after(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_DIR, secure: true
    end

    before(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_DIR, secure: true
    end

    it 'tests default values' do
      options = described_class.new
      options.parse_options
      expected = options[:out_dir]
      expect(expected).to eq(TEST_DIR)
    end
  end
end
