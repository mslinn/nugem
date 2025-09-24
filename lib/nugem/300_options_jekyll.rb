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
  end
end
