require 'optparse'
require 'optparse/time'
require_relative 'spec_helper'

class NestedOptionParserTest
  RSpec.describe OptionParser do
    option_parser = described_class.new do |parser|
      parser.on('-t TIME', '--time=TIME', Time)
      parser.on('-x', '--xray')
    end

    it 'initializes an OptionParser' do
      default_options = { time: '2020-02-12T00:00:00Z' }
      options = default_options
      option_parser.order! %w[-x -t 2025-07-01T12:00:00Z], into: options
      expect(options).to eq({ xray: true, time: Time.parse('2025-07-01T12:00:00Z') })
    end
  end
end
