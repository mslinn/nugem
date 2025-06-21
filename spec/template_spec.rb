require 'rspec/match_ignoring_whitespace'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class TemplateTest
  @gem_name = 'test_gem'
  @rspec = true
  the_binding = binding
  template = ERBTemplates::Template.new(the_binding, 'common/gem_scaffold', 'Gemfile.tt')
  template2 = ERBTemplates::Template.new(the_binding, 'common/gem_scaffold', '.shellcheckrc')

  RSpec.describe ERBTemplates::Template do
    it 'initializes with valid parameters' do
      expect(template.name).to eq('Gemfile.tt')
      expect(template.path).to eq('templates/common/gem_scaffold/Gemfile.tt')
    end

    it 'raises error for invalid binding' do
      expect do
        described_class.new(nil, 'common/gem_scaffold', 'Gemfile.tt')
      end.to raise_error(ArgumentError, 'Binding must be a valid binding object')
    end

    it 'raises error for invalid path' do
      expect do
        described_class.new(the_binding, '', '')
      end.to raise_error(ArgumentError, 'Offset must be a non-empty string')
    end

    it 'raises error for non-existent file' do
      expect do
        described_class.new(the_binding, 'common/gem_scaffold', 'non_existent_file.tt')
      end.to raise_error(ArgumentError, /Path.*non_existent_file.tt' does not exist/)
    end

    it 'renders a template with ERB' do
      actual = template.render
      expect(actual).to include('The test_gem gem dependencies are defined in test_gem.gemspec')
    end

    it 'renders a template without ERB' do
      actual = template2.render
      expect(actual).to include('disable=')
    end

    it 'writes the rendered template to a target path' do
      target_path = '/tmp/nugem/Gemfile'
      expect { template.write(target_path) }.not_to raise_error
    end

    it 'raises error if target path is not writable' do
      expect { template.write('output/Gemfile') }.to raise_error('Error writing to output/Gemfile: Permission denied')
    end

    it 'compares two templates for equality' do
      another_template = described_class.new(the_binding, 'templates/common/gem_scaffold/Gemfile.tt')
      expect(template).to eq(another_template)
    end

    it 'does not compare different templates as equal' do
      different_template = described_class.new(the_binding, 'templates/common/gem_scaffold/README.md')
      expect(template).not_to eq(different_template)
    end

    it 'raises error for permission issues when writing' do
      allow(File).to receive(:write)
                       .with('output/Gemfile', anything)
                       .and_raise(Errno::EACCES, 'Permission denied')
      expect do
        template.write('output/Gemfile')
      end.to raise_error(/Permission denied/)
    end
  end
end
