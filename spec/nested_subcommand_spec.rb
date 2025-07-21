require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'
require 'sod'
require 'sod/types/pathname'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class NestedOptionParserTest
  RSpec.describe NestedOptionParser do
    let(:nop1) do
      described_class.new(
        argv:               %w[-h -x -y -z --out_dir=/etc/hosts pos_param1 pos_param2],
        option_parser_proc: lambda do |parser|
          parser.on '-h', '--help'
          parser.on('-o', '--out_dir=OUT_DIR', Pathname, 'Output directory') { |x| puts x.green }
        end
      )
    end

    it 'initializes a NestedOptionParser' do
      expect(nop1.remaining_options).to eq(%w[-x -y -z])
      expect(nop1.positional_parameters).to eq(%w[pos_param1 pos_param2])
      expect(nop1.options).to               eq({ help: true })
      expect(nop1.argv).to                  eq(%w[-x -y -z pos_param1 pos_param2])
    end

    it 'initializes a NestedOptionParser as a subcommand NOP' do
      sub_cmd = SubCmd.new('subcmd1', proc do |parser|
        parser.on '-y', '--yes'
      end)
      nop_top = described_class.new(
        argv:               %w[-a --unused -h subcmd1 pos_param1 pos_param2 -y --out_dir . -z],
        option_parser_proc: nop1.option_parser_proc,
        sub_cmds:           [sub_cmd]
      )

      # The --out_dir and its path should be removed, but -h, -y, --out_dir should be returned.
      expect(nop_top.remaining_options).to eq(%w[-a --unused -z]) # should not get -h, -y, --out_dir .
      expect(nop_top.positional_parameters).to eq(%w[subcmd1 pos_param1 pos_param2])
      expect(nop_top.options).to               eq(%w[-h -y --out_dir=.])
      expect(nop_top.argv).to                  eq(%w[-h -y --out_dir=. pos_param1 pos_param2])
    end
  end
end
