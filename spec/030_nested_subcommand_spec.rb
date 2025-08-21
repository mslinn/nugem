require 'pathname'
require 'sod'
require 'sod/types/pathname'

require_relative 'spec_helper'
require_relative '../lib/nugem'

module Nugem
  class NestedOptionParserTest
    RSpec.describe NestedOptionParser do
      common_parser_proc = proc do |parser|
        parser.raise_unknown = false # Required for subcommand processing to work
        parser.on '-h', '--help'
        parser.on '-o', '--out_dir=OUT_DIR', Pathname
      end

      help_proc = proc do |message = nil|
        puts message.red if message
        puts <<~END_HELP
          This is a multiline help message for NestedOptionParserTest.
          It does not exit the program.
        END_HELP
      end

      it 'initializes a NestedOptionParser without a subcommand' do
        ruby_subcmd = SubCmd.new 'ruby', (proc do |parser|
          parser.on '-x', '--xray' do
            puts 'XRAY XRAY XRAY XRAY XRAY XRAY'
          end
        end)
        nop_control = NestedOptionParserControl.new(
          common_parser_proc,
          help_proc,
          ::Nugem.positional_parameter_proc,
          %w[ruby test --out_dir=/etc/hosts -y],
          {},
          [ruby_subcmd],
          ruby_subcmd
        )
        nop = described_class.new(nop_control, errors_are_fatal: false)

        options = {
          gem_type: 'ruby',
          gem_name: 'test',
          out_dir:  Pathname('/etc/hosts'),
        }
        expect(nop.options).to eq(options)
        expect(nop.argv).to    eq(%w[-y])
      end

      it 'initializes a NestedOptionParser as a subcommand NOP' do
        jekyll_subcmd = SubCmd.new 'jekyll', (proc do |parser|
          parser.on '-y', '--yes'
        end)
        nop_control = NestedOptionParserControl.new(
          common_parser_proc,
          help_proc,
          ::Nugem.positional_parameter_proc,
          %w[ruby test --yes],
          {},
          [jekyll_subcmd],
          jekyll_subcmd
        )
        nop = described_class.new nop_control, errors_are_fatal: false
        options = {
          gem_type: 'ruby',
          gem_name: 'test',
          yes:      true,
        }

        expect(nop.argv).to    eq([])
        expect(nop.options).to eq(options)
        expect(nop.argv).to    eq(%w[])
      end
    end
  end
end
