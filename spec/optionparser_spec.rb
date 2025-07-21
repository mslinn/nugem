require 'optparse'
require 'optparse/time'
require 'pathname'
require 'sod'
require 'sod/types/pathname'
require_relative 'spec_helper'

class NestedOptionParserTest
  RSpec.describe OptionParser do
    option_parser = described_class.new do |parser|
      parser.on('-o', '--out_dir=OUT_DIR', Pathname, 'Output directory')
      parser.on('-t TIME', '--time=TIME', Time)
      parser.on('-x', '--xray')
    end

    it 'parses path using short form' do
      options = {}
      option_parser.order! %w[-o /etc/hosts], into: options
      expect(options).to eq({ out_dir: Pathname('/etc/hosts') })
    end

    it 'parses path using long form' do
      options = {}
      option_parser.order! %w[--out_dir=/etc/hosts], into: options
      expect(options).to eq({ out_dir: Pathname('/etc/hosts') })
    end

    it 'parses time' do
      options = { time: '2020-02-12T00:00:00Z' } # Default value of all options
      option_parser.order! %w[-x -t 2025-07-01T12:00:00Z], into: options
      expect(options).to eq({ xray: true, time: Time.parse('2025-07-01T12:00:00Z') })
    end

    it 'parses path and time using short forms' do
      options = {}
      option_parser.order! %w[-o /etc/hosts -t 2025-07-01T12:00:00Z], into: options
      expect(options).to eq({ out_dir: Pathname('/etc/hosts'), time: Time.parse('2025-07-01T12:00:00Z') })
    end

    it 'parses path and time using long and short forms' do
      options = {}
      option_parser.order! %w[--out_dir /etc/hosts -t 2025-07-01T12:00:00Z], into: options
      expect(options).to eq({ out_dir: Pathname('/etc/hosts'), time: Time.parse('2025-07-01T12:00:00Z') })
    end

    it 'parses path and time using short and long forms' do
      options = {}
      option_parser.order! %w[-o /etc/hosts --time=2025-07-01T12:00:00Z], into: options
      expect(options).to eq({ out_dir: Pathname('/etc/hosts'), time: Time.parse('2025-07-01T12:00:00Z') })
    end

    it 'parses path and time using long forms' do
      options = {}
      option_parser.order! %w[--out_dir /etc/hosts --time=2025-07-01T12:00:00Z], into: options
      expect(options).to eq({ out_dir: Pathname('/etc/hosts'), time: Time.parse('2025-07-01T12:00:00Z') })
    end
  end
end
