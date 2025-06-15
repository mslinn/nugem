module Nugem
  class Options
    def parse_options
      options = {
        executable: false,
        host:       'github',
        private:    false,
        quiet:      true,
        todos:      true,
        yes:        false,
        out_dir:    "#{Dir.home}/nugem_generated",
        loglevel:   'warning',
      }
      # See https://ruby-doc.org/3.4.1/stdlibs/optparse/OptionParser.html
      OptionParser.new do |parser|
        parser.program_name = File.basename __FILE__
        @parser = parser

        parser.on('-e', '--executable', 'Include an executable for the generated gem')
        parser.on('-H', '--host HOST', 'Repository host (github, bitbucket)', %w[github bitbucket])
        parser.on('-l', '--loglevel LOGLEVEL', Integer, "Logging level (#{VERBOSITY.join ', '})")
        parser.on('-s', '--shake SHAKE', Integer, 'Shakiness (1..10)')
        parser.on('-v', '--verbose VERBOSE', 'Verbosity')
        parser.on('-z', '--zoom ZOOM', Integer, 'Zoom percentage')

        parser.on_tail('-h', '--help', 'Show this message') do
          help
        end
      end.order!(into: options)
      help "Invalid verbosity value (#{options[:verbose]}), must be one of one of: #{VERBOSITY.join ', '}." if options[:verbose] && !options[:verbose] in VERBOSITY
      help "Invalid shake value (#{options[:shake]})." if options[:shake].negative? || options[:shake] > 10
      options
    end
  end
end
