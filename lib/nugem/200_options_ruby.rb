require 'fileutils'
require 'sod'
require 'sod/types/pathname'

# Procs are defined separately; this file just contains high-level logic
module Nugem
  DEFAULT_OUT_DIR_BASE = File.join(Dir.home, 'nugem_generated').freeze
  HOSTS = %w[github gitlab bitbucket].freeze
  LOGLEVELS = %w[trace debug verbose info warning error fatal panic quiet].freeze

  class RubyOptions
    # @errors_are_fatal and @subcommand_parser_procs are set in the constructor
    # @options are set from defaults and overwritten by scanning ARGV
    attr_accessor :errors_are_fatal, :options, :subcommand_parser_procs

    include ::HighlineWrappers

    # @param initial_options [Hash] Should only contain :gem_type, :gem_name and :source_root
    # @param dry_run [Boolean] not used yet. TODO incorporate into runtime_options?
    # @param errors_are_fatal [Boolean] TODO incorporate into runtime_options?
    # @return [RubyOptions]
    def initialize(initial_options, dry_run: false, errors_are_fatal: true)
      @positional_parameter_proc = ::Nugem.positional_parameter_proc
      @errors_are_fatal = errors_are_fatal

      ruby_gem_option_defaults = {
        executables: [],
        dry_run:     dry_run,
        force:       false,
        host:        'github',
        loglevel:    LOGLEVELS[3], # Default is 'info'
        out_dir:     "#{DEFAULT_OUT_DIR_BASE}/#{initial_options[:gem_name]}",
        overwrite:   false,
        private:     false,
        todos:       true,
      }
      @options = ruby_gem_option_defaults # lowest priority
                   .merge(::Nugem.jekyll_plugin_option_defaults) # medium priority
                   .merge(initial_options) # highest priority
      compute_output_directory
      @options = @options.sort.to_h # Makes it easier to spot a particular option
      ::Nugem.make_subcommands
      @subcommand_parser_procs = []
    end

    def compute_output_directory
      my_gems = ENV.fetch('my_gems', nil)
      out_dir = my_gems ? File.join(my_gems, @options[:gem_name]) : @options[:out_dir]
      @options[:my_gems] = my_gems
      @options[:output_directory] = out_dir
    end

    # Constructor for NestedOptionParser using this instance's state.
    # Gather all the possible parameter values and performs type checking.
    # Subsequent methods must perform application-level sanity checks.
    # @return hash containing options
    def nested_option_parser_from(argv)
      # See https://ruby-doc.org/3.4.1/stdlibs/optparse/OptionParser.html
      # See https://ruby-doc.org/3.4.1/optparse/option_params_rdoc.html
      nop_control = NestedOptionParserControl.new(
        common_parser_proc:        ::Nugem.common_parser_proc,
        help_proc:                 ::Nugem.help_proc,
        positional_parameter_proc: ::Nugem.positional_parameter_proc,
        argv:                      argv,
        default_option_hash:       @options,
        sub_cmds:                  @subcommand_parser_procs,
        subcommand:                @subcommand_parser_procs.first # FIXME: figure out which
      )
      NestedOptionParser.new nop_control, errors_are_fatal: @errors_are_fatal
    rescue OptionParser::InvalidOption => e
      ::Nugem.help_proc&.call(e.message, errors_are_fatal: @errors_are_fatal)
      e.message # Useful for rspec tests
    end

    # Do application-level sanity check stuff then summarize if log level sufficient
    # Called after user parameters have been gathered and saved as state in this instance
    # Only generate output if loglevel is info or lower
    # @return [String] Human-friendly description of options in force
    def prepare_and_report
      dir = @options[:out_dir]
      overwrite = @options[:overwrite]
      show_log_level_info = LOGLEVELS.index(@options[:loglevel]) <= LOGLEVELS.index('info')

      if @options[:dry_run]
        puts "Dry run: skipping the removal of #{dir}".yellow if overwrite && show_log_level_info
      else
        puts "Removing #{dir}".yellow if show_log_level_info
        FileUtils.rm_rf(Dir.glob(dir), secure: true)
        FileUtils.mkdir_p dir
      end
      show_log_level_info ? summarize : ''
    end

    def summarize
      executables = @options[:executables]
      executable_msg = if executables.empty?
                         'No executables will be included'
                       elsif executables.length > 1
                         "Executables called #{executables.join ', '} will be included"
                       else
                         "An executable called #{executables.join} will be included"
                       end
      force_msg = if @options[:force]
                    'Any pre-existing content in the output directory will be deleted before generating new output.'
                  else
                    'Pre-existing content in the output directory will abort the program.'
                  end
      <<~END_SUMMARY
        RubyOptions:
         - Gem type: #{@options[:gem_type]}
         - Loglevel #{@options[:loglevel]}
         - Output directory: '#{@options[:output_directory]}'
         - #{force_msg}
         - #{executable_msg}
         - Git host: #{@options[:host]}
         - A #{@options[:private] ? 'private' : 'public'} git repository will be created
         - TODOs #{@options[:notodos] ? 'will not' : 'will'} be included in the source code
      END_SUMMARY
    end
  end
end
