require 'erb'
require 'optparse'

require_relative 'spec_helper'

RSpec.describe ObjectArrayBinding do
  let(:obj1) { Struct.new(:foo).new('foo from obj1') }
  let(:obj2) { Struct.new(:bar).new('bar from obj2') }
  let(:obj3) { Struct.new(:foo).new('foo from obj3') }

  # For ERB (not necessarily with Rails), trim_mode: '-' removes one following newline:
  #  - the newline must be the first char after the > that ends the ERB expression
  #  - no following spaces are removed
  #  - only a single newline is removed
  def render(template, objects)
    erb = ERB.new(template, trim_mode: '-')
    erb.result(ObjectArrayBinding.new(objects).get_binding)
  end

  context 'when only one object responds' do
    it 'resolves foo from obj1' do
      expect(render('<%= foo %>', [obj1, obj2])).to eq('foo from obj1')
    end

    it 'resolves bar from obj2' do
      expect(render('<%= bar %>', [obj1, obj2])).to eq('bar from obj2')
    end
  end

  context 'when no object responds' do
    it 'raises NameError' do
      expect { render('<%= baz %>', [obj1, obj2]) }.to raise_error(NameError)
    end
  end

  context 'when multiple objects respond' do
    it 'raises NameError with ambiguity message' do
      expect do
        render('<%= foo %>', [obj1, obj3])
      end.to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)
    end
  end

  context 'with respond_to?' do
    let(:binding_provider) { described_class.new([obj1, obj2]) }

    it 'returns true for foo' do
      expect(binding_provider.respond_to?(:foo)).to be true
    end

    it 'returns true for bar' do
      expect(binding_provider.respond_to?(:bar)).to be true
    end

    it 'returns false for baz' do
      expect(binding_provider.respond_to?(:baz)).to be false
    end

    it 'defines foo but raises if ambiguous' do
      provider = described_class.new([obj1, obj3])
      expect(provider.respond_to?(:foo)).to be true
      expect { provider.foo }.to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)
    end
  end
end
