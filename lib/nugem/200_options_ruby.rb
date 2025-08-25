require 'fileutils'
require 'sod'
require 'sod/types/pathname'

# Procs are defined separately; this file just contains high-level logic
module Nugem
  DEFAULT_OUT_DIR_BASE = File.join(Dir.home, 'nugem_generated').freeze
  HOSTS = %w[github gitlab bitbucket].freeze
  LOGLEVELS = %w[trace debug verbose info warning error fatal panic quiet].freeze

  class Options
    attr_accessor :errors_are_fatal, :options, :subcommand_parser_procs

    include ::HighlineWrappers

    def initialize(default_options, dry_run: false, errors_are_fatal: true)
      @positional_parameter_proc = ::Nugem.positional_parameter_proc
      @errors_are_fatal = errors_are_fatal

      ruby_gem_options = {
        executable: [],
        dry_run:    dry_run,
        force:      false,
        host:       'github',
        loglevel:   LOGLEVELS[3], # Default is 'info'
        out_dir:    "#{DEFAULT_OUT_DIR_BASE}/#{default_options[:gem_name]}",
        overwrite:  false,
        private:    false,
        todos:      true,
      }
      @options = default_options
                   .merge(ruby_gem_options)
                   .merge(::Nugem.jekyll_plugin_options)
                   .sort
                   .to_h

      @subcommand_parser_procs = [NestedOptionParserControl.jekyll_subcommand]
    end

    # Gather all the possible parameter values and performs type checking.
    # Subsequent methods must perform application-level sanity checks.
    # @return hash containing options
    def nested_option_parser_from(argv)
      # See https://ruby-doc.org/3.4.1/stdlibs/optparse/OptionParser.html
      # See https://ruby-doc.org/3.4.1/optparse/option_params_rdoc.html
      nop_control = NestedOptionParserControl.new(
        ::Nugem.common_parser_proc,
        ::Nugem.help_proc,
        ::Nugem.positional_parameter_proc,
        argv,
        @options,
        @subcommand_parser_procs
      )
      NestedOptionParser.new nop_control, errors_are_fatal: @errors_are_fatal
    rescue OptionParser::InvalidOption => e
      ::Nugem.help_proc&.call(e.message, errors_are_fatal: @errors_are_fatal)
      e.message # Useful for rspec tests
    end

    # Do application-level sanity check stuff then summarize if log level sufficient
    # Called after user parameters have been gathered and saved as state in this instance
    # Only generate output if loglevel is info or lower
    def prepare_and_report
      dir = @options[:out_dir]
      overwrite = @options[:overwrite]
      show_log_level_info = LOGLEVELS.index(@options[:loglevel]) <= LOGLEVELS.index('info')

      nugem_options

      if @options[:dry_run]
        puts "Dry run: skipping the removal of #{dir}".yellow if overwrite && show_log_level_info
      else
        puts "Removing #{dir}".yellow if show_log_level_info
        FileUtils.rm_rf(Dir.glob(dir), secure: true)
        Dir.mkdir dir
      end
      show_log_level_info ? summarize : ''
    end

    def summarize
      executable_msg = if @options[:executable].empty?
                         'No executables will be included'
                       elsif @options[:executable].length > 1
                         "Executables called #{@options[:executable].join ', '} will be included"
                       else
                         "An executable called #{@options[:executable].join} will be included"
                       end
      force_msg = if @options[:force]
                    'Any pre-existing content in the output directory will be deleted before generating new output.'
                  else
                    'Pre-existing content in the output directory will abort the program.'
                  end
      <<~END_SUMMARY
        Options:
         - Gem type: #{@options[:gem_type]}
         - Loglevel #{@options[:loglevel]}
         - Output directory: '#{@options[:out_dir]}'
         - #{force_msg}
         - #{executable_msg}
         - Git host: #{@options[:host]}
         - A #{@options[:private] ? 'private' : 'public'} git repository will be created
         - TODOs #{@options[:notodos] ? 'will not' : 'will'} be included in the source code
      END_SUMMARY
    end
  end
end
