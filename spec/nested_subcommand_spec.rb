require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class NestedOptionParserTest
  RSpec.describe NestedOptionParser do
    let(:nop1) do
      described_class.new(
        default_options = {},
        proc do |parser|
          parser.on '-h', '--help'
          parser.on '-o', '--out_dir OUT_DIR'
        end
      )
    end

    it 'initializes a NestedOptionParser' do
      expect(nop1.unmatched_args).to        eq(%w[-x -y -z])
      expect(nop1.positional_parameters).to eq(%w[pos_param1 pos_param2])
      expect(nop1.options).to eq(%w[-h])
      expect(nop1.argv).to eq(%w[-h pos_param1 pos_param2])
    end

    it 'initializes a NestedOptionParser and a subNOP' do
      nop2 = described_class.new(
        {},
        proc do |parser|
          parser.on '-h', '--help'
          parser.on '-o', '--out_dir OUT_DIR'
        end
      )

      nop_top = described_class.new(nop1, nop2, argv: %w[-a --blah -h -x pos_param1 pos_param2 -y -z])

      # TODO: figure out expected values; these are placeholders
      expect(nop_top.unmatched_args).to        eq(%w[-a -y -z])
      expect(nop_top.positional_parameters).to eq(%w[pos_param1 pos_param2])
      expect(nop_top.options).to eq(%w[-h])
      expect(nop_top.argv).to eq(%w[-h pos_param1 pos_param2])
    end
  end
end
