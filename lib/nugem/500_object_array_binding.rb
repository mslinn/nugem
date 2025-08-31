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
# binding_array = ObjectArrayBinding.new([obj1, obj2])
# erb = ERB.new template, trim_mode: '-'
# expanded_template = erb.result binding_array
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

  def define_delegators!
    method_map = Hash.new { |h, k| h[k] = [] } # Collect all public methods across objects

    @objects.each do |obj|
      # Do not include public methods from ancestors of obj
      obj.public_methods(false).each { |m| method_map[m] << obj }
    end

    method_map.each do |method_name, responders|
      case responders.size
      when 0
        # do nothing because respond_to? will return false
      when 1
        define_singleton_method(method_name) do |*args, &block|
          responders.first.public_send(method_name, *args, &block)
        end
      else
        define_singleton_method(method_name) do |*| # no arguments are passed to this block
          signatures = responders.map(&:to_s).join(', ')
          raise AmbiguousMethodError, "Ambiguous method '#{method_name}': multiple objects respond: #{signatures}"
        end
      end
    end
  end
end
