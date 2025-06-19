# Nugem::Cli is a class that is invoked when a user runs a nugem executable.
# This file defines the common aspects of the class.
module Nugem
  class Cli
    # These declarations make the class instance variable values available as an accessor,
    # which is necessary to name template files that are named '%variable_name%.extension'.
    # See https://www.rubydoc.info/gems/thor/Thor/Actions#directory-instance_method
    attr_reader :block_name, :filter_name, :generator_name, :tag_name, :test_framework

    # Surround gem_name with percent symbols when using the property to name files
    # within the template directory
    # For example: "generated/%gem_name%"
    attr_accessor :gem_name
  end
end
