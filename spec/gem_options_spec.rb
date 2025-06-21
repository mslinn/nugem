require 'fileutils'
require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class GemOptionsTest
  ARGV.clear
  ARGV = '-L debug gem'.freeze

  DEFAULT_TEST_DIR = File.join(Dir.home, 'nugem_generated').freeze
  TEST_DIR = File.join(Dir.tmpdir, 'nugem/test').freeze

  RSpec.describe ::Nugem::Options do
    after(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_DIR, secure: true
    end

    before(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_DIR, secure: true
    end

    it 'tests default values' do
      gem_options = described_class.new
      options = gem_options.parse_options(parse_dry_run: true)
      expect(options[:out_dir]).to eq(DEFAULT_TEST_DIR)
    end
  end
end
