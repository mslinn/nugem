require_relative 'spec_helper'
require_relative '../lib/nugem'

class NestedOptionParserTest
  RSpec.describe NestedOptionParser do
    def help(message = nil)
      puts message.red if message
      puts <<~END_HELP
        This is a multiline help message.
        It does not exit the program.
      END_HELP
    end

    option_parser_proc = proc do |parser|
      parser.raise_unknown = false # Required for subcommand processing to work
      parser.on '-h', '--help'
      parser.on '-o', '--out_dir=OUT_DIR', Pathname
    end

    it 'initializes a NestedOptionParser' do
      nop = described_class.new(
        argv:               %w[-h --out_dir=/etc/hosts -y pos_param1 pos_param2],
        help:               method(:help),
        option_parser_proc: option_parser_proc
      )

      expect(nop.remaining_options).to     eq(%w[-y])
      expect(nop.positional_parameters).to eq(%w[pos_param1 pos_param2])
      expect(nop.options).to               eq({ help: true, out_dir: Pathname('/etc/hosts') })
      expect(nop.argv).to                  eq(%w[-y pos_param1 pos_param2])
    end

    it 'initializes a NestedOptionParser as a subcommand NOP' do
      sub_cmd = SubCmd.new('subcmd1', proc do |parser|
        parser.on '-y', '--yes'
      end)
      nop = described_class.new(
        argv:               %w[-h --out_dir=/etc/hosts -y subcmd1 pos_param1 pos_param2],
        help:               method(:help),
        option_parser_proc: option_parser_proc,
        sub_cmds:           [sub_cmd]
      )

      expect(nop.remaining_options).to     eq([])
      expect(nop.positional_parameters).to eq(%w[pos_param1 pos_param2])
      expect(nop.options).to               eq({ help: true, out_dir: Pathname('/etc/hosts'), yes: true })
      expect(nop.argv).to                  eq(%w[pos_param1 pos_param2])
    end
  end
end
