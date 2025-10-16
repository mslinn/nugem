require 'fileutils'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/nugem'

# Tests for Jekyll plugin generation
RSpec.describe 'Jekyll Plugin Generation' do
  let(:test_out_dir) { File.join(Dir.tmpdir, "nugem_test_#{Time.now.to_i}") }

  after(:each) do
    FileUtils.rm_rf(test_out_dir, secure: true) if File.exist?(test_out_dir)
  end

  before(:each) do
    FileUtils.rm_rf(test_out_dir, secure: true) if File.exist?(test_out_dir)
  end

  describe 'Generator plugin' do
    it 'creates a generator scaffold' do
      initial_options = {
        gem_name:    'test_generator',
        gem_type:    'jekyll',
        source_root: File.expand_path('../templates', __dir__),
      }
      options = Nugem::JekyllOptions.new(initial_options, errors_are_fatal: false)
      options.options[:generator] = ['my_generator']
      options.options[:output_directory] = test_out_dir
      options.options[:force] = true

      nugem = Nugem::Nugem.new(options.options)
      nugem.generate_ruby_scaffold
      nugem.generate_jekyll_scaffold

      # Verify generator file was created
      generator_file = File.join(test_out_dir, 'lib', 'my_generator.rb')
      expect(File.exist?(generator_file)).to be true

      # Verify it contains expected content
      content = File.read(generator_file)
      expect(content).to include('class MyGenerator < Jekyll::Generator')
      expect(content).to include('def generate(site)')
    end
  end

  describe 'Hooks plugin' do
    it 'creates a hooks scaffold' do
      initial_options = {
        gem_name:    'test_hooks',
        gem_type:    'jekyll',
        source_root: File.expand_path('../templates', __dir__),
      }
      options = Nugem::JekyllOptions.new(initial_options, errors_are_fatal: false)
      options.options[:hooks] = ['hooks']  # hooks expects an array
      options.options[:output_directory] = test_out_dir
      options.options[:force] = true

      nugem = Nugem::Nugem.new(options.options)
      nugem.generate_ruby_scaffold
      nugem.generate_jekyll_scaffold

      # Verify hooks file was created
      hooks_file = File.join(test_out_dir, 'lib', 'hooks.rb')
      expect(File.exist?(hooks_file)).to be true

      # Verify it contains expected content
      content = File.read(hooks_file)
      expect(content).to include('Jekyll::Hooks.register')
      expect(content).to include(':site')
      expect(content).to include(':pages')
    end
  end

  describe 'No-arg tag plugin' do
    it 'creates a tagn scaffold' do
      initial_options = {
        gem_name:    'test_tagn',
        gem_type:    'jekyll',
        source_root: File.expand_path('../templates', __dir__),
      }
      options = Nugem::JekyllOptions.new(initial_options, errors_are_fatal: false)
      options.options[:tagn] = ['simple_tag']
      options.options[:output_directory] = test_out_dir
      options.options[:force] = true

      nugem = Nugem::Nugem.new(options.options)
      nugem.generate_ruby_scaffold
      nugem.generate_jekyll_scaffold

      # Verify tag file was created
      tag_file = File.join(test_out_dir, 'lib', 'simple_tag.rb')
      expect(File.exist?(tag_file)).to be true

      # Verify it contains expected content
      content = File.read(tag_file)
      expect(content).to include('class SimpleTag < JekyllSupport::JekyllTag')
      expect(content).to include('def render_impl')
      expect(content).to include('NoArgParsing')
    end
  end

  describe 'No-arg block plugin' do
    it 'creates a blockn scaffold' do
      initial_options = {
        gem_name:    'test_blockn',
        gem_type:    'jekyll',
        source_root: File.expand_path('../templates', __dir__),
      }
      options = Nugem::JekyllOptions.new(initial_options, errors_are_fatal: false)
      options.options[:blockn] = ['simple_block']
      options.options[:output_directory] = test_out_dir
      options.options[:force] = true

      nugem = Nugem::Nugem.new(options.options)
      nugem.generate_ruby_scaffold
      nugem.generate_jekyll_scaffold

      # Verify block file was created
      block_file = File.join(test_out_dir, 'lib', 'simple_block.rb')
      expect(File.exist?(block_file)).to be true

      # Verify it contains expected content
      content = File.read(block_file)
      expect(content).to include('class SimpleBlock < JekyllSupport::JekyllBlock')
      expect(content).to include('def render_impl(content)')
      expect(content).to include('NoArgParsing')
    end
  end

  describe 'Common scaffold' do
    it 'creates common Jekyll files' do
      initial_options = {
        gem_name:    'test_common',
        gem_type:    'jekyll',
        source_root: File.expand_path('../templates', __dir__),
      }
      options = Nugem::JekyllOptions.new(initial_options, errors_are_fatal: false)
      options.options[:tagn] = ['simple_tag']
      options.options[:output_directory] = test_out_dir
      options.options[:force] = true

      nugem = Nugem::Nugem.new(options.options)
      nugem.generate_ruby_scaffold
      nugem.generate_jekyll_scaffold

      # Verify spec helper was created
      spec_helper = File.join(test_out_dir, 'spec', 'spec_helper.rb')
      expect(File.exist?(spec_helper)).to be true

      # Verify demo directory structure was created
      demo_index = File.join(test_out_dir, 'demo', 'index.html')
      expect(File.exist?(demo_index)).to be true

      # Verify demo contains tag example
      content = File.read(demo_index)
      expect(content).to include('simple_tag')
    end
  end

  describe 'Multiple plugin types' do
    it 'creates multiple plugin types in one gem' do
      initial_options = {
        gem_name:    'test_multi',
        gem_type:    'jekyll',
        source_root: File.expand_path('../templates', __dir__),
      }
      options = Nugem::JekyllOptions.new(initial_options, errors_are_fatal: false)
      options.options[:tagn] = ['my_tag']
      options.options[:blockn] = ['my_block']
      options.options[:generator] = ['my_generator']
      options.options[:output_directory] = test_out_dir
      options.options[:force] = true

      nugem = Nugem::Nugem.new(options.options)
      nugem.generate_ruby_scaffold
      nugem.generate_jekyll_scaffold

      # Verify all files were created
      expect(File.exist?(File.join(test_out_dir, 'lib', 'my_tag.rb'))).to be true
      expect(File.exist?(File.join(test_out_dir, 'lib', 'my_block.rb'))).to be true
      expect(File.exist?(File.join(test_out_dir, 'lib', 'my_generator.rb'))).to be true

      # Verify demo includes examples for tag and block
      demo_index = File.join(test_out_dir, 'demo', 'index.html')
      content = File.read(demo_index)
      expect(content).to include('my_tag')
      expect(content).to include('my_block')
    end
  end
end
