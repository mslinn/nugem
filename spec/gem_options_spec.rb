require 'fileutils'
require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class GemOptionsTest
  TEST_OUT_DIR = File.join(Dir.tmpdir, 'nugem_test').freeze

  RSpec.describe ::Nugem::Options do
    after(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    before(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    it 'tests gem with loglevel debug and summarize' do
      argv = ['-L', 'debug', 'gem']
      options = described_class.new(errors_are_fatal: false)
      debug_options = options.value.merge({ loglevel: 'debug' })

      actual = options.parse_options(argv_override: argv)
      expect(actual).to eq(debug_options)

      actual_summary = options.act
      expected_summary = <<~END_SUMMARY
        Loglevel #{options.value[:loglevel]}
        Output directory: '#{options.value[:out_dir]}'
        No executables will be included
        Git host: github
        A public git repository will be created
        TODOs will be included in the source code
        User responses will be used for yes/no questions
      END_SUMMARY
      expect(actual_summary).to eq(expected_summary)
    end

    it 'tests gem with loglevel debug and executable blah' do
      argv = [
        '-e', 'blah',
        '-H', 'bitbucket',
        '-L', 'debug',
        '-o', TEST_OUT_DIR,
        '-N',
        '-p',
        '-y',
        'gem'
      ]
      options = described_class.new(errors_are_fatal: false)
      actual = options.parse_options(argv_override: argv)
      expected = options.value.merge({
                                       executables: ['blah'],
                                       loglevel:    'debug',
                                       out_dir:     TEST_OUT_DIR,
                                       private:     true,
                                     })
      expect(actual).to eq(expected)

      actual_summary = options.act
      expected_summary = <<~END_SUMMARY
        Loglevel #{options.value[:loglevel]}
        Output directory: '#{options.value[:out_dir]}'
        An executable called blah will be included
        Git host: bitbucket
        A private git repository will be created
        TODOs will be included in the source code
        All questions will be automatically be answered with 'yes'
      END_SUMMARY
      expect(actual_summary).to eq(expected_summary)
    end

    it 'tests gem for loglevel debug and 2 executables' do
      argv = ['-L', 'debug', '-e', 'ex1,ex2', 'gem']
      options = described_class.new(errors_are_fatal: false)
      expected = options.value.merge({
                                       executables: %w[ex1 ex2],
                                       loglevel:    'debug',
                                     })
      actual = options.parse_options(argv_override: argv)
      expect(actual).to eq(expected)
    end

    it 'handles invalid options' do
      argv = ['-L', 'debug', '-x', 'gem']
      options = described_class.new(errors_are_fatal: false)
      actual = options.parse_options(argv_override: argv)
      expect(actual).to eq('invalid option: -x')
    end
  end
end
