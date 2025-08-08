module Nugem
  class JekyllOptions < Options
    def initialize(default_options, errors_are_fatal: true)
      super
    end

    # @param argv_override should not contain positional parameters, just options
    def parse_options(argv_override, dry_run: false)
      options = super # calls a method of the same name in the super class and passes above arguments
      options.merge!({
                       block:     [],
                       blockn:    [],
                       filter:    [],
                       generator: [],
                       tag:       [],
                       tagn:      [],
                     })
      OptionParser.new do |parser|
        # All of the following can have multiple occurances on a command line, except hooks
        parser.on('-B', '--block=BLOCK') do |value|        # Specifies the name of a Jekyll block tag.
          options[:block] << value
        end
        parser.on '-f', '--filter=FILTER' do |value|       # Specifies the name of a Jekyll/Liquid filter module.
          options[:filter] << value
        end
        parser.on '-g', '--generator=GENERATOR' do |value| # Specifies a Jekyll generator.
          options[:generator] << value
        end
        parser.on '-K', '--hooks=HOOKS'                    # Generate Jekyll hooks.
        parser.on '-N', '--blockn=BLOCK' do |value|        # Specifies the name of a Jekyll no-arg block tag.
          options[:blockn] << value
        end
        parser.on '-n', '--tagn=TAG' do |value|            # Specifies the name of a Jekyll no-arg tag.
          options[:tagn] << value
        end
        parser.on '-t', '--tag=TAG' do |value|             # Specifies the name of a Jekyll tag.
          options[:tag] << value
        end
      end.order! argv_override, into: options
      options
    rescue OptionParser::InvalidOption => e
      ::Nugem.help(e.message, errors_are_fatal: @errors_are_fatal)
      e.message # Useful for rspec tests
    end
  end
end
