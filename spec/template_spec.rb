require_relative 'spec_helper'
require_relative '../lib/templates'

class JekyllTagTest
  @gem_name = 'test_gem'
  @rspec = true
  the_binding = binding
  template = Templates::Template.new(the_binding, 'templates/common/gem_scaffold/Gemfile.tt')
  template2 = Templates::Template.new(the_binding, 'templates/common/gem_scaffold/.shellcheckrc')

  RSpec.describe Templates::Template do
    it 'initializes with valid parameters' do
      expect(template.name).to eq('Gemfile.tt')
      expect(template.path).to eq('templates/common/gem_scaffold/Gemfile.tt')
    end

    it 'raises error for invalid binding' do
      expect { described_class.new(nil, 'templates/common/gem_scaffold/Gemfile.tt') }
        .to raise_error(ArgumentError, 'Binding must be a valid binding object')
    end

    it 'raises error for invalid path' do
      expect { described_class.new(the_binding, '') }
        .to raise_error(ArgumentError, 'Path must be a non-empty string')
    end

    it 'raises error for non-existent file' do
      expect { described_class.new(the_binding, 'non_existent_file.tt') }
        .to raise_error(ArgumentError, /Path 'non_existent_file.tt' does not exist/)
    end

    it 'renders a template with ERB' do
      actual = template.render
      expect(actual).to include("source 'https://rubygems.org'\n\n# The test_gem gem dependencies are defined in test_gem.gemspec")
    end

    it 'renders a template without ERB' do
      actual = template2.render
      expect(actual).to include('disable=')
    end

    it 'raises error for rendering issues' do
      allow(File).to receive(:read)
                       .with('templates/common/gem_scaffold/Gemfile.tt')
                       .and_raise(StandardError, 'Rendering error')
      expect { template.render }.to raise_error(/Rendering error/)
    end

    it 'returns a string representation of the template' do
      expect(template.to_s).to eq('Gemfile.tt (templates/common/gem_scaffold/Gemfile.tt)')
    end

    it 'writes the rendered template to a target path' do
      target_path = 'output/Gemfile'
      allow(File).to receive(:write)
                       .with(target_path, "source 'https://rubygems.org'\n\ngem 'test_gem'")
      expect { template.write(target_path) }.not_to raise_error
    end

    it 'raises error if target path is not writable' do
      allow(File).to receive(:write)
                       .with('output/Gemfile', anything)
                       .and_raise(StandardError, 'Permission denied')
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
