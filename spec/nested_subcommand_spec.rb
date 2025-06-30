require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class NestedOptionParserTest
  RSpec.describe NestedOptionParser do
    let(:nop1) do
      described_class.new(
        argv:               %w[-x -y -z pos_param1 pos_param2],
        option_parser_proc: proc do |parser|
          parser.on '-h', '--help'
          parser.on '-o', '--out_dir OUT_DIR'
        end
      )
    end

    it 'initializes a NestedOptionParser' do
      expect(nop1.remaining_argv).to        eq(%w[-x -y -z])
      expect(nop1.positional_parameters).to eq(%w[pos_param1 pos_param2])
      expect(nop1.options).to eq(%w[-h])
      expect(nop1.argv).to eq(%w[-h pos_param1 pos_param2])
    end

    it 'initializes a NestedOptionParser as a subcommand NOP' do
      nop2 = described_class.new(
        sub_name:           'nop2',
        option_parser_proc: proc do |parser|
          parser.on '-y', '--yes'
          parser.on '-o', '--out_dir OUT_DIR'
        end
      )

      nop_top = described_class.new(
        option_parser_proc:      nop1,
        subcommand_parser_procs: [nop2],
        argv:                    %w[-a --unused -h pos_param1 pos_param2 -y --out_dir . -z]
      )

      # TODO: figure out expected values; these are placeholders
      expect(nop_top.remaining_argv).to        eq(%w[-a --unused -z])
      expect(nop_top.positional_parameters).to eq(%w[pos_param1 pos_param2])
      expect(nop_top.options).to eq(%w[-h -y --out_dir .])
      expect(nop_top.argv).to eq(%w[-h -y --out_dir . pos_param1 pos_param2])
    end
  end
end
