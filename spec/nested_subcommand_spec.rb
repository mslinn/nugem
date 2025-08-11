require 'pathname'
require 'sod'
require 'sod/types/pathname'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class NestedOptionParserTest
  help_lambda = proc do |message = nil|
    puts message.red if message
    puts <<~END_HELP
      This is a multiline help message.
      It does not exit the program.
    END_HELP
  end

  RSpec.describe NestedOptionParser do
    option_parser_proc = proc do |parser|
      parser.raise_unknown = false # Required for subcommand processing to work
      parser.on '-h', '--help'
      parser.on '-o', '--out_dir=OUT_DIR', Pathname
    end

    it 'initializes a NestedOptionParser' do
      nested_option_parser_control = NestedOptionParserControl.new(
        option_parser_proc,
        help_lambda,
        %w[-h --out_dir=/etc/hosts -y pos_param1 pos_param2],
        {},
        []
      )
      nop = described_class.new nested_option_parser_control

      expect(nop.remaining_options).to     eq(%w[-y])
      expect(nop.positional_parameters).to eq(%w[pos_param1 pos_param2])
      expect(nop.options).to               eq({ help: true, out_dir: Pathname('/etc/hosts') })
      expect(nop.argv).to                  eq(%w[-y pos_param1 pos_param2])
    end

    it 'initializes a NestedOptionParser as a subcommand NOP' do
      sub_cmd = SubCmd.new('subcmd1', proc do |parser|
        parser.on '-y', '--yes'
      end)
      nested_option_parser_control = NestedOptionParserControl.new(
        option_parser_proc,
        help_lambda,
        %w[-h --out_dir=/etc/hosts -y subcmd1 pos_param1 pos_param2],
        {},
        [sub_cmd]
      )
      nop = described_class.new nested_option_parser_control

      expect(nop.remaining_options).to     eq([])
      expect(nop.positional_parameters).to eq(%w[pos_param1 pos_param2])
      expect(nop.options).to               eq({ help: true, out_dir: Pathname('/etc/hosts'), yes: true })
      expect(nop.argv).to                  eq(%w[pos_param1 pos_param2])
    end
  end
end
