require 'rspec/match_ignoring_whitespace'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class JekyllTagTest
  ARGV = 'gem' # rubocop:disable Style/MutableConstant
  RSpec.describe ::Nugem::Options do
    it 'tests default values' do
      options = described_class.new
      out_dir = options.parse_dir '/tmp/nugem/test', options.default_options[:out_dir]
      expect(out_dir).to eq('/tmp/nugem/test')
    end
  end
end
