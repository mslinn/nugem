require 'erb'
require 'optparse'

require_relative 'spec_helper'

RSpec.describe ObjectArrayBinding do
  let(:obj1) { Struct.new(:foo).new('foo from obj1') }
  let(:obj2) { Struct.new(:bar).new('bar from obj2') }
  let(:obj3) { Struct.new(:foo).new('foo from obj3') }

  let(:oab)   { described_class.new }
  let(:oab12) { described_class.new(objects: [obj1, obj2]) }
  let(:oab13) { described_class.new([obj1, obj3]) }

  context 'when only one object responds' do
    it 'resolves foo from obj1' do
      expect(oab12.render('<%= foo %>')).to eq('foo from obj1')
    end

    it 'resolves bar from obj2' do
      expect(oab12.render('<%= bar %>')).to eq('bar from obj2')
    end
  end

  context 'when no object responds' do
    it 'raises NameError with no bindings' do
      expect { oab.render('<%= baz %>') }.to raise_error(NameError)
    end

    it 'raises NameError with no matching method' do
      expect { oab12.render('<%= baz %>') }.to raise_error(NameError)
    end
  end

  context 'when multiple objects respond' do
    it 'raises NameError with ambiguity message' do
      expect do
        oab13.render('<%= foo %>')
      end.to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)
    end
  end

  context 'with respond_to?' do
    it 'returns true for foo' do
      expect(oab12.respond_to?(:foo)).to be true
    end

    it 'returns true for bar' do
      expect(oab12.respond_to?(:bar)).to be true
    end

    it 'returns false for baz' do
      expect(oab12.respond_to?(:baz)).to be false
    end

    it 'defines foo but raises AmbiguousMethodError if more than one object defines the desired method' do
      expect(oab13.respond_to?(:foo)).to be true
      expect { oab13.foo }.to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)
    end
  end
end
