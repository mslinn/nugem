require_relative 'spec_helper'

class BlockProcLambdaTest
  RSpec.describe OptionParser do
    aproc = proc do |parser|
      parser.on '-h', '--help'
      parser.on '-o', '--out_dir=OUT_DIR'
    end
    option_parser = described_class.new(&aproc)

    it 'parses path using short form' do
      options = {}
      option_parser.order! %w[-o /etc/hosts], into: options
      expect(options).to eq({ out_dir: '/etc/hosts' })
    end

    it 'parses path using long form' do
      options = {}
      option_parser.order! %w[--out_dir=/etc/hosts], into: options
      expect(options).to eq({ out_dir: '/etc/hosts' })
    end
  end
end
