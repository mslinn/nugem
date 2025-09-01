require 'erb'
require 'optparse'

require_relative 'spec_helper'

module TestHelpers
  def self.version = '9.9.9'
  def self.helper  = 'helper called'
  def self.greet(name) = "Hello, #{name}!"

  def self.with_block
    yield 'block arg'
  end
end

module OtherHelpers
  def self.helper = 'other helper'
end

RSpec.describe ArbitraryContextBinding do
  let(:oab) { described_class.new }

  let(:repository_class) { Struct.new(:user_name) }
  let(:project_class)    { Struct.new(:title) }
  let(:repository)  { repository_class.new('alice') }
  let(:project)     { project_class.new('cool app') }
  let(:oab_objects) { described_class.new(objects: [repository, project]) }

  let(:obj1) { Struct.new(:foo).new('foo from obj1') }
  let(:obj2) { Struct.new(:bar).new('bar from obj2') }
  let(:obj3) { Struct.new(:foo).new('foo from obj3') }
  let(:oab12) { described_class.new(objects: [obj1, obj2]) }
  let(:oab13) { described_class.new(objects: [obj1, obj3]) }

  let(:oab_module) { described_class.new(modules: [TestHelpers]) }
  let(:oab_modules) { described_class.new(modules: [OtherHelpers, TestHelpers]) }

  obj = Struct.new(:helper).new('object helper')
  let(:oab_dup_method) { described_class.new(modules: [TestHelpers], objects: [obj]) }

  let(:oab_all) do
    described_class.new(
      objects:      [obj1, obj2, obj3],
      modules:      [TestHelpers],
      base_binding: binding
    )
  end

  before do # define pre-existing ivars in test scope
    @repository = repository
    @project    = project
  end

  describe 'using pre-existing instance variables' do
    it 'renders instance variable values from caller scope' do
      template = 'User: <%= @repository.user_name %>, Project: <%= @project.title %>'
      result = oab_all.render(template)
      expect(result).to eq('User: alice, Project: cool app')
    end
  end

  describe 'delegation from modules' do
    it 'delegates multiple methods from a module' do
      template = 'v=<%= version %>, h=<%= helper %>'
      result = oab_module.render(template)
      expect(result).to eq('v=9.9.9, h=helper called')
    end

    it 'delegates module methods with arguments' do
      template = "<%= greet('bob') %>"
      result = oab_module.render(template)
      expect(result).to eq('Hello, bob!')
    end

    it 'delegates module methods that take a block' do
      template = '<%= with_block { |x| x.upcase } %>'
      result = oab_module.render(template)
      expect(result).to eq('BLOCK ARG')
    end

    it 'raises if multiple modules define the same method' do
      template = '<%= helper %>'
      expect do
        oab_modules.render(template)
      end.to raise_error(AmbiguousMethodError, /Ambiguous method 'helper'/)
    end
  end

  describe 'delegation from objects' do
    it 'delegates methods from objects' do
      template = 'User: <%= user_name %>, Title: <%= title %>'
      result = oab_objects.render(template)
      expect(result).to eq('User: alice, Title: cool app')
    end
  end

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

  context 'when multiple objects and/or modules respond' do
    it 'raises NameError with ambiguity message' do
      expect do
        oab13.render('<%= foo %>')
      end.to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)
    end

    it 'raises if a module and an object both respond to the same method' do
      obj = Struct.new(:helper).new('object helper')
      template = '<%= helper %>'

      expect do
        oab_dup_method.render(template)
      end.to raise_error(AmbiguousMethodError, /Ambiguous method 'helper'/)
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
