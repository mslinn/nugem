require 'fileutils'
require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class RubyOptionsTest
  TEST_OUT_DIR = File.join(Dir.tmpdir, 'nugem_test').freeze

  RSpec.describe ::Nugem::Options do
    after(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    before(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    it 'tests ruby gem with loglevel debug and summarize' do
      hash = { force: true, gem_type: 'ruby', out_dir: TEST_OUT_DIR }
      nugem_options = described_class.new(hash, errors_are_fatal: false)
      actual = nugem_options.nested_option_parser_from ['ruby', 'test', '-f', '-o', TEST_OUT_DIR, '-L', 'debug'],
                                                       allow_unknown_options: false,
                                                       dry_run:               true
      expected = nugem_options.options.merge({ loglevel: 'debug' })
      expect(actual).to eq(expected)

      actual_summary = nugem_options.prepare_and_report
      expected_summary = <<~END_SUMMARY
        Options:
         - Gem type: ruby
         - Loglevel #{nugem_options.options[:loglevel]}
         - Output directory: '#{nugem_options.options[:out_dir]}'
         - Any pre-existing content in the output directory will be deleted before generating new output.
         - No executables will be included
         - Git host: github
         - A public git repository will be created
         - TODOs will be included in the source code
      END_SUMMARY
      expect(actual_summary).to eq(expected_summary)
    end

    it 'tests ruby gem with bitbucket, debug, executable, force, no todos, out_dir and private' do
      argv = [
        'ruby', 'test',
        '-e', 'blah',
        '-f',
        '-H', 'bitbucket',
        '-L', 'debug',
        '-o', TEST_OUT_DIR,
        '-n',
        '-p'
      ]
      nugem_options = described_class.new({ gem_type: 'ruby' }, errors_are_fatal: false)
      actual = nugem_options.nested_option_parser_from(argv, allow_unknown_options: false, dry_run: true)
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
         - Any pre-existing content in the output directory will be deleted before generating new output.
         - An executable called blah will be included
         - Git host: bitbucket
         - A private git repository will be created
         - TODOs will not be included in the source code
      END_SUMMARY
      expect(actual_summary).to eq(expected_summary)
    end

    it 'tests ruby gem for loglevel debug and 2 executables' do
      argv = %w[ruby test -e ex1 -e ex2 --loglevel=debug]
      nugem_options = described_class.new({ gem_type: 'ruby' }, errors_are_fatal: false)
      expected = nugem_options.options.merge({
                                               executable: %w[ex1 ex2],
                                               loglevel:   'debug',
                                             })
      actual = nugem_options.nested_option_parser_from(argv, allow_unknown_options: false, dry_run: true)
      expect(actual).to eq(expected)
    end

    it 'handles invalid options' do
      argv = %w[ruby test -L debug -x]
      nugem_options = described_class.new({ gem_type: 'ruby' }, errors_are_fatal: false)
      actual = nugem_options.nested_option_parser_from(argv, allow_unknown_options: false, dry_run: true)
      expect(actual).to eq('invalid option: -x')
    end
  end
end
