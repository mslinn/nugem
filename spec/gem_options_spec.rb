require 'fileutils'
require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class GemOptionsTest
  DEFAULT_OUT_DIR = File.join(Dir.home,   'nugem_generated').freeze
  TEST_OUT_DIR    = File.join(Dir.tmpdir, 'nugem_test').freeze

  RSpec.describe ::Nugem::Options do
    let(:argv) { ['-L', 'debug', 'gem'] }
    let(:options) { described_class.new }
    let(:debug_options) { options.default_options + { loglevel: argv[1] } }

    after(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    before(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    it 'tests gem with loglevel debug' do
      actual = options.parse_options(argv_override: argv)
      expect(actual).to eq(debug_options)
    end

    it 'tests gem with loglevel debug and summarize' do
      actual = options.parse_options(argv_override: argv)
      actual_summary = actual.act_and_summarize(options, parse_dry_run: true)
      expected_summary = <<~END_SUMMARY
        Loglevel #{LOGLEVELS.index(options[:loglevel])}
        Output directory: '#{options[:out_dir]}'
        No executable will be included
        Git host: github
        A public git repository will be created
        TODOs will be included in the source code
        User responses will be used for yes/no questions
      END_SUMMARY
      expect(actual_summary).to eq(expected_summary)
    end
  end
end
