require 'optparse'
require 'optparse/time'
require 'pathname'
require 'sod'
require 'sod/types/pathname'

require_relative 'spec_helper'

class OptionParserTest
  options = {}
  RSpec.describe OptionParser do
    option_parser = described_class.new do |parser|
      parser.on '-n', '--notodos', TrueClass
      parser.on '-o', '--out_dir=OUT_DIR', Pathname
      parser.on '-t TIME', '--time=TIME', Time
      parser.on '-w WORD', '--word=WORD' do |word|
        options[:word] << word # Add each occurrence of -w or --word to the :word array
      end
      parser.on '-x', '--xray'
    end

    it 'parses --notodos option' do
      options = { word: [] }
      option_parser.order! %w[-n], into: options
      expected = { notodos: true, word: [] }
      expect(options).to eq(expected)
    end

    it 'parses multiple instances of the same option' do
      options = { word: [] }
      option_parser.order! %w[-w word1 -w word2 --word word3], into: options
      expected = { word: %w[word1 word2 word3] }
      expect(options).to eq(expected)
    end

    it 'parses path using short form' do
      options = {}
      option_parser.order! %w[-o /etc/hosts], into: options
      expect(options).to eq({ out_dir: Pathname('/etc/hosts') })
    end

    it 'parses toggle and path using short form' do
      options = {}
      option_parser.order! %w[-x -o /etc/hosts], into: options
      expect(options).to eq({ out_dir: Pathname('/etc/hosts'), xray: true })
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
