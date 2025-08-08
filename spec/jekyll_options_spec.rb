require 'fileutils'
require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class JekyllOptionsTest
  TEST_OUT_DIR = File.join(Dir.tmpdir, 'nugem_test').freeze

  RSpec.describe ::Nugem::JekyllOptions do
    after(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    before(:context) do # rubocop:disable RSpec/BeforeAfterAll
      FileUtils.rm_rf TEST_OUT_DIR, secure: true
    end

    it 'tests jekyll plugin with loglevel debug and summarize' do
      # Very similar to first test in RubyOptionsTest
      hash = { force: true, gem_type: 'jekyll', out_dir: TEST_OUT_DIR }
      nugem_options = described_class.new(hash, errors_are_fatal: false)
      actual = nugem_options.parse_options ['-f', '-o', TEST_OUT_DIR, '-L', 'debug', 'ruby', 'test'], dry_run: true
      expected = nugem_options.options.merge({ loglevel: 'debug' })
      expect(actual).to eq(expected)

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
  end
end
