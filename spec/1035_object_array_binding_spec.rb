require 'erb'
require 'optparse'

# require_relative '../500_object_array_binding'
require_relative 'spec_helper'

# source_path = 'templates/common/executable_scaffold/exe/%gem_name%.tt'

RSpec.describe ObjectArrayBinding do
  let(:obj1) { Struct.new(:foo).new('foo from obj1') }
  let(:obj2) { Struct.new(:bar).new('bar from obj2') }
  let(:obj3) { Struct.new(:foo).new('foo from obj3') }

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
      end.to raise_error(NameError, /Ambiguous method 'foo'/)
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

    it 'returns false if multiple objects respond' do
      provider = described_class.new([obj1, obj3])
      expect(provider.respond_to?(:foo)).to be false
    end
  end
end
