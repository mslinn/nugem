require 'erb'

# Provides a binding that resolves methods against an array of objects,
# but raises if more than one object responds to the same method.
# Both public and private methods will be found.
class ObjectArrayBinding
  def initialize(objects)
    @objects = objects
  end

  def get_binding
    binding
  end

  # See https://www.leighhalliday.com/ruby-metaprogramming-method-missing
  def method_missing(name, ...)
    responders = @objects.select { |o| o.respond_to?(name) }
    case responders.size
    when 0
      super
    when 1
      responders.first.public_send(name, ...)
    else
      signatures = responders.map(&:to_s).join(', ')
      raise NameError,
            "Ambiguous method '#{name}': multiple objects (#{signatures}) respond."
    end
  end

  def respond_to_missing?(name, include_private = false)
    count = @objects.count { |o| o.respond_to?(name, include_private) }
    count == 1 || super
  end
end
