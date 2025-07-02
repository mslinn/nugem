require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class NestedOptionParserTest
  RSpec.describe NestedOptionParser do
    let(:nop1) do
      described_class.new(
        default_argv:       %w[-h -x -y -z pos_param1 pos_param2],
        option_parser_proc: proc do |parser|
          parser.on '-h', '--help'
          parser.on '-o', '--out_dir OUT_DIR'
        end
      )
    end

    it 'initializes a NestedOptionParser' do
      expect(nop1.remaining_argv).to        eq(%w[-x -y -z])
      expect(nop1.positional_parameters).to eq(%w[pos_param1 pos_param2])
      expect(nop1.options).to eq({ help: true })
      expect(nop1.argv).to eq(%w[-x -y -z pos_param1 pos_param2])
    end

    it 'initializes a NestedOptionParser as a subcommand NOP' do
      sub_cmd = SubCmd.new('subcmd1', proc do |parser|
        parser.on '-y', '--yes'
      end)
      nop_top = described_class.new(
        option_parser_proc: nop1.option_parser_proc,
        sub_cmds:           [sub_cmd],
        default_argv:       %w[-a --unused -h subcmd1 pos_param1 pos_param2 -y --out_dir . -z]
      )

      # TODO: figure out expected values; these are placeholders
      # The --out_dir path was removed, but -h, -y, --out_dir were returned.
      expect(nop_top.remaining_argv).to        eq(%w[-a --unused -z]) # should not get -h, -y, --out_dir .
      expect(nop_top.positional_parameters).to eq(%w[subcmd1 pos_param1 pos_param2])
      expect(nop_top.options).to               eq(%w[-h -y --out_dir .])
      expect(nop_top.argv).to                  eq(%w[-h -y --out_dir . pos_param1 pos_param2])
    end
  end
end
