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
      argv = %w[ruby test -o /dir -L debug]
      nugem_options = described_class.new({ gem_type: 'ruby' }, errors_are_fatal: false)
      expected = nugem_options.options.merge({ loglevel: 'debug' })

      actual = nugem_options.parse_options argv
      expect(actual).to eq(expected)

      actual_summary = nugem_options.prepare_and_report
      expected_summary = <<~END_SUMMARY
        Options:
         - Gem type: ruby
         - Loglevel #{nugem_options.options[:loglevel]}
         - Output directory: '#{nugem_options.options[:out_dir]}'
         - Pre-existing content in the output directory will abort the program.
         - No executables will be included
         - Git host: github
         - A public git repository will be created
         - TODOs will be included in the source code
      END_SUMMARY
      expect(actual_summary).to eq(expected_summary)
    end

    it 'tests ruby gem with loglevel debug and executable blah' do
      argv = [
        'ruby', 'test',
        '-e', 'blah',
        '-H', 'bitbucket',
        '-L', 'debug',
        '-o', TEST_OUT_DIR,
        '-N',
        '-p',
        '-y'
      ]
      nugem_options = described_class.new({ gem_type: 'ruby' }, errors_are_fatal: false)
      actual = nugem_options.parse_options(argv_override: argv)
      expected = nugem_options.options.merge({
                                               executable: ['blah'],
                                               loglevel:   'debug',
                                               out_dir:    TEST_OUT_DIR,
                                               private:    true,
                                             })
      expect(actual).to eq(expected)

      actual_summary = nugem_options.prepare_and_report
      expected_summary = <<~END_SUMMARY
        Options:
         - Gem type: ruby
         - Loglevel #{nugem_options.options[:loglevel]}
         - Output directory: '#{nugem_options.options[:out_dir]}'
         - Pre-existing content in the output directory will abort the program.
         - An executable called blah will be included
         - Git host: bitbucket
         - A private git repository will be created
         - TODOs will be included in the source code
      END_SUMMARY
      expect(actual_summary).to eq(expected_summary)
    end

    it 'tests gem for loglevel debug and 2 executables' do
      argv = %w[ruby test -e ex1 -e ex2 -L debug]
      nugem_options = described_class.new({ gem_type: 'ruby' }, errors_are_fatal: false)
      expected = nugem_options.options.merge({
                                               executables: %w[ex1 ex2],
                                               loglevel:    'debug',
                                             })
      actual = nugem_options.parse_options(argv_override: argv)
      expect(actual).to eq(expected)
    end

    it 'handles invalid options' do
      argv = %w[ruby test -L debug -x]
      nugem_options = described_class.new({ gem_type: 'ruby' }, errors_are_fatal: false)
      actual = nugem_options.parse_options(argv_override: argv)
      expect(actual).to eq('invalid option: -x')
    end
  end
end
