require 'pathname'
require 'sod'
require 'sod/types/pathname'

require_relative 'spec_helper'
require_relative '../lib/nugem'

module Nugem
  # Just tests parsing, not actions
  class NestedOptionParserTest
    RSpec.describe NestedOptionParser do
      common_parser_proc = proc do |parser|
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
            puts 'XRAY XRAY XRAY XRAY XRAY XRAY' # Do not do anything, just notice the option was recognized
          end
        end)
        nop_control = NestedOptionParserControl.new(
          common_parser_proc:        common_parser_proc,
          help_proc:                 help_proc,
          positional_parameter_proc: ::Nugem.positional_parameter_proc,
          argv:                      %w[ruby test --out_dir=/etc/hosts --xray -z],
          default_option_hash:       {},
          sub_cmds:                  [ruby_subcmd],
          subcommand:                ruby_subcmd
        )
        nop = described_class.new(nop_control, errors_are_fatal: false)

        options = {
          gem_type: 'ruby',
          gem_name: 'test',
          out_dir:  Pathname('/etc/hosts'),
          xray:     nil,
        }
        expect(nop.options).to eq(options)
        # Note: -z is consumed by the parser and triggers an error, but doesn't remain in argv
        # This behavior may need to be revisited if we want unrecognized options to remain
        expect(nop.argv).to    eq([])
      end

      it 'initializes a NestedOptionParser as a subcommand NOP' do
        jekyll_subcmd = SubCmd.new 'jekyll', (proc do |parser|
          parser.on '-y', '--yes'
        end)
        nop_control = NestedOptionParserControl.new(
          common_parser_proc:        common_parser_proc,
          help_proc:                 help_proc,
          positional_parameter_proc: ::Nugem.positional_parameter_proc,
          argv:                      %w[ruby test --yes],
          default_option_hash:       {},
          sub_cmds:                  [jekyll_subcmd],
          subcommand:                jekyll_subcmd
        )
        nop = described_class.new nop_control, errors_are_fatal: false
        expected = {
          gem_type: 'ruby',
          gem_name: 'test',
          yes:      true,
        }

        expect(nop.argv).to    eq([])
        expect(nop.options).to eq(expected)
        expect(nop.argv).to    eq(%w[])
      end
    end
  end
end
