require 'fileutils'
require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class OutDirTest
  TEST_OUT_DIR = File.join(Dir.tmpdir, 'nugem_test').freeze

  RSpec.describe 'Output directory' do
    after(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    before(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    it 'blah blah' do
      ENV.delete 'my_gems'
      actual = ''
      expected = ''
      expect(actual).to eq(expected)
    end
  end
end
