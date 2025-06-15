require 'FileUtils'

module Nugem
  class Options
    VERBOSITY = %w[trace debug verbose info warning error fatal panic quiet].freeze

    def parse_options
      options = {
        executable: false,
        host:       'github',
        loglevel:   VERBOSITY[4], # Default is 'warning'
        out_dir:    "#{Dir.home}/nugem_generated",
        private:    false,
        quiet:      true,
        todos:      true,
        yes:        false,
      }
      # See https://ruby-doc.org/3.4.1/stdlibs/optparse/OptionParser.html
      # See https://ruby-doc.org/3.4.1/optparse/option_params_rdoc.html
      OptionParser.new do |parser|
        parser.program_name = File.basename __FILE__
        @parser = parser

        parser.on('-e', '--executable', FalseClass, 'Include an executable for the generated gem')
        parser.on('-HHOST', '--host', %w[github bitbucket], 'Repository host')
        parser.on('GEM_NAME', 'Repository host')
        parser.on('-oOUT_DIR', '--out_dir', 'Output directory for the gem') do |dir|
          dir ||= options[:out_dir]
          if Dir.exist?(dir) && !Dir.empty?(dir)
            puts "Output directory '#{dir}' already exists and is not empty."
            overwrite = if options[:yes]
                          puts "Overwriting contents of #{dir} because --yes was specified."
                          true
                        else
                          ask "Do you want to overwrite the contents of #{dir}? (y/n)"
                        end
            if overwrite
              FileUtils.rm_r Dir.glob(dir), force: true, secure: true
              Dir.mkdir dir
            end
          end
          puts "Output directory set to '#{dir}'."
          options[:out_dir] = dir
        end
        parser.on('-lLOGLEVEL', '--loglevel', VERBOSITY, 'Logging level')
        parser.on('-p',         '--private',  FalseClass, 'Publish the gem to a private repository')
        parser.on('-t',         '--todos',    TrueClass,  'Generate TODO: messages in generated code')
        parser.on('-y',         '--yes',      FalseClass, 'Answer yes to all questions')

        parser.on_tail('-h', '--help', 'Show this message') do
          help
        end
      end.order!(into: options)

      help('The type and name of the gem to create was not specfied.') if ARGV.empty?
      help('Invalid syntax.') if ARGV.length > 2
      help("The gem type must be one of: #{Nugem::GEM_TYPES.join(', ')}") unless Nugem::GEM_TYPES.include? ARGV[0]

      @options[:gem_type] = ARGV[0]
      @options[:gem_name] = ARGV[1]

      help('Invalid gem name.') if @options[:gem_name]

      options
    end
  end
end
