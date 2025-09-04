require_relative 'spec_helper'
require_relative '../lib/nugem'

module Nugem
  class ValuesTest
    # Ensure that all variables referenced by ERB templates resolve
    RSpec.describe 'ERB references' do
      def nugem_from_argv(argv)
        original_verbose = $VERBOSE # See https://avdi.codes/temporarily-disabling-warnings-in-ruby/
        $VERBOSE = nil
        Object.const_set :ARGV, argv
        $VERBOSE = original_verbose

        options = ::Nugem.parse_gem_type_name # Only sets the :gem_type and :gem_name
        options[:source_root] = File.expand_path('../templates', File.dirname(__FILE__)) # templates live here
        nugem_options = Options.new options
        nugem_options.prepare_and_report
        Nugem.new nugem_options.options
      end

      it 'out_dir special handling using -o' do
        nugem = nugem_from_argv %w[ruby test -o /a/b/c/my_gems]
        expect(nugem.acb.render('<%= @gem_name %>')).to eq('test')
      end

      it 'out_dir special handling using current directory' do
        ENV.delete 'my_gems'
        nugem = nugem_from_argv %w[ruby test]
        expect(nugem.acb.render('<%= @out_dir %>')).to eq(File.join(Dir.pwd, 'test'))
        expect(nugem.acb.render('<%= @out_dir %>')).to eq(File.join(Dir.pwd, 'test'))
      end

      it 'out_dir special handling using $my_gems' do
        ENV['my_gems'] = '/a/b/c/my_gems'
        nugem = nugem_from_argv %w[ruby test]
        expect(nugem.acb.render('<%= @out_dir %>')).to eq('/a/b/c/my_gems/test')
      end

      it 'resolves local variables within the Nugem.initialize method' do
        ENV['my_gems'] = '/a/b/c/my_gems'
        nugem = nugem_from_argv %w[ruby test]
        expect(nugem.acb.render('<%= repository_user_name %>')).to eq('Mike Slinn')
      end

      it 'resolves instance variables defined within the Nugem.initialize method' do
        ENV['my_gems'] = '/a/b/c/my_gems'
        nugem = nugem_from_argv %w[ruby test]
        expect(nugem.acb.render('<%= @class_name %>')).to                 eq('Test')
        expect(nugem.acb.render('<%= @force %>')).to                      eq('false')
        expect(nugem.acb.render('<%= @gem_name %>')).to                   eq('test')
        expect(nugem.acb.render('<%= @module_name %>')).to                eq('TestModule')
        expect(nugem.acb.render('<%= @options[:gem_name] %>')).to         eq('test')
        expect(nugem.acb.render('<%= @repository.host.camel_case %>')).to eq('GitHub')
        expect(nugem.acb.render('<%= @repository.name %>')).to            eq('test')
        expect(nugem.acb.render('<%= @repository.private %>')).to         eq('false')
        expect(nugem.acb.render('<%= @repository.user %>')).to            eq('Mike Slinn')
      end
    end
  end
end
