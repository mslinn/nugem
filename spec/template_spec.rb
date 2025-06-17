require_relative 'spec_helper'
require_relative '../lib/templates'

class JekyllTagTest
  RSpec.describe Templates::Template do
  it 'initializes with valid parameters' do
    @gem_name = 'test_gem'
    @rspec = true
    binding = binding()
    template = Templates::Template.new(binding, 'templates/common/gem_scaffold/Gemfile.tt')
    expect(template.name).to eq('Gemfile.tt')
    expect(template.path).to eq('templates/common/gem_scaffold/Gemfile.tt')
  end
end
