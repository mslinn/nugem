require 'erb'
require 'optparse'

require_relative 'spec_helper'

RSpec.describe ObjectArrayBinding do
  let(:obj1) { Struct.new(:foo).new('foo from obj1') }
  let(:obj2) { Struct.new(:bar).new('bar from obj2') }
  let(:obj3) { Struct.new(:foo).new('foo from obj3') }

  context 'when only one object responds' do
    let(:oab) { described_class.new([obj1, obj2]) }

    it 'resolves foo from obj1' do
      expect(oab.render('<%= foo %>')).to eq('foo from obj1')
    end

    it 'resolves bar from obj2' do
      expect(oab.render('<%= bar %>')).to eq('bar from obj2')
    end
  end

  context 'when no object responds' do
    let(:oab) { described_class.new([obj1, obj2]) }

    it 'raises NameError' do
      expect { oab.render('<%= baz %>') }.to raise_error(NameError)
    end
  end

  context 'when multiple objects respond' do
    let(:oab) { described_class.new([obj1, obj3]) }

    it 'raises NameError with ambiguity message' do
      expect do
        oab.render('<%= foo %>')
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
