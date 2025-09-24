module Nugem
  # These declarations make the class instance variable values available as an accessor,
  # which is necessary to name template files that are named '%variable_name%.extension'.
  # See https://www.rubydoc.info/gems/thor/Thor/Actions#directory-instance_method
  attr_reader :block_name, :filter_name, :generator_name, :tag_name

  # Surround gem_name with percent symbols when using the property to name files
  # within the template directory
  # For example: "~/nugem_generated/%gem_name%"
  attr_accessor :gem_name

  class JekyllOptions < RubyOptions
    def initialize(default_options, dry_run: false, errors_are_fatal: true)
      super
      @subcommand_parser_procs = [::Nugem.jekyll_subcommand]
    end

    def summarize
      block_msg     = summary_helper :block, 'Block'
      blockn_msg    = summary_helper :blockn, 'BlockN'
      filter_msg    = summary_helper :filter, 'Filter'
      generator_msg = summary_helper :generator, 'Generator'
      hook_msg      = summary_helper :hook, 'Hook'
      tag_msg       = summary_helper :tag, 'Tag'
      tagn_msg      = summary_helper :tagn, 'TagN'

      summary_lines = "#{tag_msg}#{tagn_msg}#{block_msg}#{blockn_msg}#{filter_msg}#{generator_msg}#{hook_msg}"
      jekyll_msg = if summary_lines.empty?
                     'No JekyllOptions were specified so I kicked back and went to sleep.'
                   else
                     <<~END_MSG
                       JekyllOptions:
                       #{summary_lines}
                     END_MSG
                   end
      super + jekyll_msg
    end

    private

    def summary_helper(key, name)
      value = @options[key]
      if value.nil? || value.empty?
        ''
      elsif value.length > 1
        " - #{name}s called #{value.join ', '} will be generated\n"
      else
        " - A #{name.downcase} called #{value.join} will be generated\n"
      end
    end
  end
end
