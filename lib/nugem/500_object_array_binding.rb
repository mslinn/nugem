require 'erb'

class AmbiguousMethodError < StandardError; end

# Provide a binding that resolves methods against an array of objects,
# but raises NameError if more than one object responds to the same method.
# Only public methods will be found.
#
# Unlike an approach that uses method_missing, this delegation approach invokes real methods created with
# define_singleton_method. This means the methods can be used with respond_to? and the code runs much faster.
#
# Note that ambiguous methods return true in response to respond_to?, but raise NameError when invoked.
#
# @example
# oab = ObjectArrayBinding.new([obj1, obj2])
# expanded_template = oab.render template
class ObjectArrayBinding
  def initialize(objects)
    @objects = objects
    define_delegators!
  end

  def get_binding
    binding
  end

  def render(template)
    # For ERB (not necessarily with Rails), trim_mode: '-' removes one following newline:
    #  - the newline must be the first char after the > that ends the ERB expression
    #  - no following spaces are removed
    #  - only a single newline is removed
    erb = ERB.new template, trim_mode: '-'
    erb.result get_binding
  end

  private

  # Ensure all public method names in @objects are unique; ancestors are not examined
  def define_delegators!
    # Passing a block to Hash.new tells Ruby what to do when you access a missing key.
    # The block takes two arguments:
    #   h - the hash itself
    #   k - the missing key
    # Inside the block: h[k] = []
    #   This creates a new empty array and assigns it as the value for that key.
    #   So the next time you access the key, the value is already set to an empty array.
    method_map = Hash.new { |h, k| h[k] = [] } # Collect all public methods across objects

    # Store an entry for each public method from every object
    # Ignore public methods from ancestors of obj
    @objects.each do |obj|
      obj.public_methods(false).each { |m| method_map[m] << obj }
    end

    # Ensure only one method per name is defined
    method_map.each do |method_name, responders|
      case responders.size
      when 0 # This should not be possible
        # Do nothing because respond_to? will return false and a NameError will be raised if invoked as usual
      when 1 # Happy path: exactly one responder
        define_singleton_method(method_name) do |*args, &block|
          responders.first.public_send(method_name, *args, &block)
        end
      else # Error: more than one responder
        define_singleton_method(method_name) do |*| # no arguments are passed to this block
          signatures = responders.map(&:to_s).join(', ')
          raise AmbiguousMethodError, "Ambiguous method '#{method_name}': multiple objects respond: #{signatures}"
        end
      end
    end
  end
end
