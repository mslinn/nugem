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
class ObjectArrayBinding
  def initialize(objects)
    @objects = objects
    define_delegators!
  end

  def get_binding
    binding
  end

  private

  def define_delegators!
    # Collect all public methods across objects
    method_map = Hash.new { |h, k| h[k] = [] }

    @objects.each do |obj|
      obj.public_methods(false).each do |m|
        method_map[m] << obj
      end
    end

    method_map.each do |method_name, responders|
      if responders.size == 1
        define_singleton_method(method_name) do |*args, &block|
          responders.first.public_send(method_name, *args, &block)
        end
      elsif responders.size > 1
        define_singleton_method(method_name) do |*| # no arguments are passed to this block
          signatures = responders.map(&:to_s).join(', ')
          raise AmbiguousMethodError, "Ambiguous method '#{method_name}': multiple objects respond: #{signatures}"
        end
      end
      # if 0 responders: don’t call define_singleton_method; respond_to? will be false
    end
  end
end
