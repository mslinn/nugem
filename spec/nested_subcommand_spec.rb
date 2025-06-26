require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class NestedOptionParserTest
  RSpec.describe NestedOptionParser do
    it 'initializes with an option parser and a subcommand parser' do
      option_parser = double('OptionParser')
      subcommand_parser = double('SubcommandParser')

      parser = described_class.new(option_parser, subcommand_parser)

      expect(parser.instance_variable_get(:@option_parser)).to eq(option_parser)
      expect(parser.instance_variable_get(:@subcommand_parser)).to eq(subcommand_parser)
    end
  end
end
