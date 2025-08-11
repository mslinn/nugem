require 'fileutils'
require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class JekyllOptionsTest
  TEST_OUT_DIR = File.join(Dir.tmpdir, 'nugem_test').freeze

  RSpec.describe Nugem::JekyllOptions do
    after do
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    before do
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    it 'tests jekyll plugin without help but with loglevel debug and summarize' do
      # Very similar to first test in RubyOptionsTest
      hash = { force: true, gem_type: 'jekyll', out_dir: TEST_OUT_DIR }
      nugem_options = described_class.new(hash, dry_run: true, errors_are_fatal: false)
      nop = nugem_options.nested_option_parser_from ['jekyll', 'test', '-f', '-o', TEST_OUT_DIR, '-L', 'debug']

      expected = nugem_options.options.merge({ loglevel: 'debug' })
      expect(nop.options).to eq(expected)

      actual_summary = nugem_options.prepare_and_report
      expected_summary = <<~END_SUMMARY
        Options:
          - Gem type: jekyll
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

    it 'tests jekyll plugin without help, with 2 blockns, 2 blocks, 1 filter, 1 generator, hooks, 2 tagns, and 1 tag' do
      nugem_options = described_class.new({ gem_type: 'jekyll' }, errors_are_fatal: false)
      argv = [
        'jekyll', 'test',
        '-B', 'block_n_2',
        '--blockn=block_n_1',
        '--block=block_1',
        '-b', 'block_2',
        '--filter=filter_1',
        '-g', 'generator_1',
        '-K',
        '-T', 'tagn_1',
        '--tagn=tagn_2',
        '-t', 'tag_1'
      ]
      nop = nugem_options.nested_option_parser_from argv
      expected = nugem_options.options.merge({
                                               blockn:    ['block_n_1'],
                                               block:     %w[block_1 block_2],
                                               filter:    ['filter_1'],
                                               generator: ['generator_1'],
                                               hooks:     true,
                                               loglevel:  'info',
                                               out_dir:   TEST_OUT_DIR,
                                               private:   false,
                                               tag:       ['tag_1'],
                                               tagn:      %w[tagn_1 tagn_2],
                                             })
      expect(nop.options).to eq(expected)
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
  end
end
