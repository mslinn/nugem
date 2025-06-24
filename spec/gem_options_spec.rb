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

    let(:argv2) do
      [
        '-e', 'blah',
        '-H', 'bitbucket',
        '-L', 'debug',
        '-o', TEST_OUT_DIR,
        '-N',
        '-p',
        '-y',
        'gem'
      ]
    end
    let(:options2) { described_class.new }
    let(:debug_options2) do
      options2.default_options +
        {
          executable: argv2[3],
          loglevel:   argv2[1],
          out_dir:    TEST_OUT_DIR,
          private:    true,
        }
    end

    let(:argv3) { ['-L', 'debug', '-e', 'ex1', '-e', 'ex2', 'gem'] }
    let(:options3) { described_class.new }
    let(:debug_options3) do
      options3.default_options +
        {
          executable: [argv3[3], argv3[5]],
          loglevel:   argv3[1],
        }
    end

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

    it 'tests gem with loglevel debug and executable blah' do
      actual = options2.parse_options(argv_override: argv2)
      actual_summary = actual.act_and_summarize(options2, parse_dry_run: true)
      expected_summary = <<~END_SUMMARY
        Loglevel #{LOGLEVELS.index(options2[:loglevel])}
        Output directory: '#{options2[:out_dir]}'
        An executable called blah will be included
        Git host: github
        A public git repository will be created
        TODOs will be included in the source code
        All questions will be automatically be answered with 'yes'
      END_SUMMARY
      expect(actual_summary).to eq(expected_summary)
    end

    it 'tests gem for loglevel debug and 2 execuables' do
      actual = options3.parse_options(argv_override: argv3)
      expect(actual).to eq(debug_options3)
    end
  end
end
