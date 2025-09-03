require 'fileutils'
require 'gem_support'
require 'rspec/expectations'
require 'rspec/match_ignoring_whitespace'
require 'tmpdir'

require_relative 'spec_helper'
require_relative '../lib/nugem'

class ValuesTest
  # Ensure that all variables referenced by ERB templates resolve
  RSpec.describe 'ERB references' do
    def setup(argv)
      Object.const_set :ARGV, argv
      options = Nugem.parse_gem_type_name # Only sets the :gem_type and :gem_name
      options[:source_root] = File.expand_path('../../templates', File.dirname(__FILE__)) # templates live here
      nugem_options = Options.new options
      nugem_options.prepare_and_report
      Nugem.new nugem_options.options
    end

    it 'out_dir special handling using -o' do
      nugem = setup %w[ruby test -o /a/b/c/my_gems]
      expect(nugem.acb.render('<% @gem_name %>')).to eq('test')
    end

    it 'out_dir special handling using current directory' do
      ENV.delete 'my_gems'
      nugem = setup %w[ruby test]
      expect(nugem.acb.render('<% @out_dir %>')).to eq(File.join(Dir.pwd, 'test'))
    end

    it 'out_dir special handling using $my_gems' do
      ENV['my_gems'] = '/a/b/c/my_gems'
      nugem = setup %w[ruby test]
      expect(nugem.acb.render('<% @out_dir %>')).to eq('/a/b/c/my_gems/test')
    end

    it 'resolve ERB variables using the ArbitraryContextBinding instance within nugem' do
      ENV['my_gems'] = '/a/b/c/my_gems'
      nugem = setup %w[ruby test]
      expect(nugem.acb.render('<% @gem_name %>')).to eq('test')
    end
  end
end
