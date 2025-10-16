require 'rainbow/refinement'
require 'rspec/match_ignoring_whitespace'

require_relative 'spec_helper'
require_relative '../lib/nugem'

using Rainbow

module Nugem
  class TemplateTest
    RSpec.describe 'Directory entry processing'.cyan do
      def cleanup(dest_path_fq)
        dirs = Dir.glob('.?*', base: dest_path_fq)
        if dirs.empty?
          puts "  Temporary directory #{dest_path_fq} is empty.".yellow
        else
          puts "  Contents of #{dest_path_fq} were, before deletion:".green
          puts "    #{dirs.join("\n    ")}".rstrip.green
        end
        FileUtils.rm_rf dest_path_fq
      end

      context 'when handling a regular file'.cyan do
        dest_base = Dir.mktmpdir('nugem_spec_') # Cannot use let vars in after clause
        nugem = Nugem.new({
                            force:    true,
                            gem_name: 'my_gem',
                            gem_type: 'ruby',
                            host:     'github',
                            out_dir:  dest_base,
                            private:  false,
                          })
        path_fragment = 'common/gem_scaffold/.rspec'
        source_path_fq = File.join File.expand_path('templates'), path_fragment
        dest_path_fq = "#{dest_base}/.rspec"

        it 'just copies it'.cyan do
          nugem.directory_entry source_path_fq, dest_path_fq, path_fragment.end_with?('.tt')
          expect(File.exist?(dest_path_fq)).to be true
        end

        after { cleanup dest_base } # rubocop:disable RSpec/HooksBeforeExamples
      end

      context 'when handling a template'.cyan do
        dest_base = Dir.mktmpdir('nugem_spec_') # Cannot use let vars in after clause
        nugem = Nugem.new({
                            force:    true,
                            gem_name: 'my_gem',
                            gem_type: 'ruby',
                            host:     'github',
                            out_dir:  dest_base,
                            private:  false,
                          })
        path_fragment = 'common/LICENCE.txt.tt'
        source_path_fq = File.join File.expand_path('templates'), path_fragment
        dest_path_fq = "#{dest_base}/LICENCE.txt"

        it 'copies to a file with a new name, set mode, and render contents'.cyan do
          nugem.directory_entry source_path_fq, dest_path_fq, path_fragment.end_with?('.tt')
          expect(File.exist?(dest_path_fq)).to be true
          # TODO: check mode
          # TODO: check contents are rendered
        end

        after { cleanup dest_base } # rubocop:disable RSpec/HooksBeforeExamples
      end
    end
  end
end
