require_relative 'spec_helper'
require_relative '../lib/templates'

class JekyllTagTest
  @gem_name = 'test_gem'
  @rspec = true
  binding = binding()
  template = Templates::Template.new(binding, 'templates/common/gem_scaffold/Gemfile.tt')

  RSpec.describe Templates::Template do
    it 'initializes with valid parameters' do
      expect(template.name).to eq('Gemfile.tt')
      expect(template.path).to eq('templates/common/gem_scaffold/Gemfile.tt')
    end

    it 'raises error for invalid binding' do
      expect { described_class.new(nil, 'templates/common/gem_scaffold/Gemfile.tt') }
        .to raise_error(ArgumentError, 'Binding must be a valid binding object')
    end

    it 'raises error for an invalid name' do
      expect { described_class.new(binding, '') }
        .to raise_error(ArgumentError, 'Name must be a non-empty string')
    end

    it 'raises error for invalid path' do
      expect { described_class.new(binding, '') }
        .to raise_error(ArgumentError, 'Path must be a non-empty string')
    end

    it 'raises error for non-existent file' do
      expect { described_class.new(binding, 'non_existent_file.tt') }
        .to raise_error(ArgumentError, 'Path must point to a valid file')
    end

    it 'renders a template with ERB' do
      allow(File).to receive(:read).with('templates/common/gem_scaffold/Gemfile.tt').and_return("source 'https://rubygems.org'\n\ngem '<%= @gem_name %>'")
      expect(template.render).to include("source 'https://rubygems.org'\n\ngem 'test_gem'")
    end

    it 'renders a template without ERB' do
      allow(File).to receive(:read).with('templates/common/gem_scaffold/README.md').and_return("# Test Gem\n\nThis is a test gem.")
      template_no_erb = described_class.new(binding, 'templates/common/gem_scaffold/README.md')
      expect(template_no_erb.render).to include("# Test Gem\n\nThis is a test gem.")
    end

    it 'raises error for non-existent template file' do
      expect do
        template.render
      end.to raise_error('Template file not found: templates/common/gem_scaffold/Gemfile.tt. Error: No such file or directory @ rb_sysopen - templates/common/gem_scaffold/Gemfile.tt')
    end

    it 'raises error for rendering issues' do
      allow(File).to receive(:read).with('templates/common/gem_scaffold/Gemfile.tt').and_raise(StandardError, 'Rendering error')
      expect { template.render }.to raise_error('Error rendering template templates/common/gem_scaffold/Gemfile.tt: Rendering error')
    end

    it 'returns a string representation of the template' do
      expect(template.to_s).to eq('Gemfile.tt (templates/common/gem_scaffold/Gemfile.tt)')
    end

    it 'writes the rendered template to a target path' do
      target_path = 'output/Gemfile'
      allow(File).to receive(:write).with(target_path, "source 'https://rubygems.org'\n\ngem 'test_gem'")
      expect { template.write(target_path) }.not_to raise_error
    end

    it 'raises error if target path is not writable' do
      allow(File).to receive(:write).with('output/Gemfile', anything).and_raise(StandardError, 'Permission denied')
      expect { template.write('output/Gemfile') }.to raise_error('Error writing to output/Gemfile: Permission denied')
    end

    it 'compares two templates for equality' do
      another_template = described_class.new(binding, 'templates/common/gem_scaffold/Gemfile.tt')
      expect(template).to eq(another_template)
    end

    it 'does not compare different templates as equal' do
      different_template = described_class.new(binding, 'templates/common/gem_scaffold/README.md')
      expect(template).not_to eq(different_template)
    end

    it 'raises error for permission issues when writing' do
      allow(File).to receive(:write).with('output/Gemfile', anything).and_raise(Errno::EACCES, 'Permission denied')
      expect do
        template.write('output/Gemfile')
      end.to raise_error('Permission denied when writing expanded template to output/Gemfile. Error: Permission denied')
    end
  end
end
