require 'optparse'
require 'optparse/time'
require_relative 'spec_helper'

class NestedOptionParserTest
  RSpec.describe OptionParser do
    ENV['POSIXLY_CORRECT'] = 'true'
    options = {}
    option_parser = described_class.new do |parser|
      parser.default_argv = %w[-t 2023-10-01T12:00:00Z]
      parser.on('-t', '--time=TIME') { |time| options[:time] = time }
      parser.on('-x', '--x') { |x| options[:x] = x }
    end
    x = option_parser.parse!(%w[-x -t 2023-10-01T12:00:00Z], into: options)

    it 'initializes an OptionParser' do
      expect(x).to eq(%w[-x -y -z])
    end
  end
end
