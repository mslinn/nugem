require 'erb'

class AmbiguousMethodError < StandardError; end

# Provide a binding that resolves methods against an array of objects,
# but raises NameError if more than one object responds to the same method.
# Only public methods will be found.
#
# modules/classes can also contribute methods to delegation resolution, not just be exposed as constants.
#
# That way your ERB can use:
#  - Instance vars: <%= @repository.user_name %>
#  - Delegated instance methods: <%= user_name %>
#  - Module and class methods: <%= Project.version %>
#  - Delegated module methods: <%= version %>
#
# By default, instance variable names are derived from class names (UserRepo → @userrepo, Project → @project).
# You can override them by passing ivar_names. For example, the following defines @repository and @project:
#
#   ObjectArrayBinding.new([repo, project], ivar_names: ["repository", "project"])
#
# Unlike an approach that uses method_missing, this delegation approach invokes real methods created with
# define_singleton_method. This means the methods can be used with respond_to? and the code runs much faster.
#
# Note that ambiguous methods return true in response to respond_to?, but raise NameError when invoked.
#
# @example
# oab = ObjectArrayBinding.new([obj1, obj2])
# expanded_template = oab.render template
class ArbitraryContextBinding
  # ivars: aligns with objects: by index.
  # modules: are made visible inside ERB (so you can call Project.version, etc.).
  def initialize(base_binding: binding, objects: [], modules: [])
    @objects = objects.dup
    @modules = modules.dup
    @base_binding = base_binding
    define_module_constants!
    define_delegators!
  end

  def get_binding
    # Use the *caller’s binding* (so pre-existing instance vars are available)
    @base_binding
  end

  def render(template)
    # For ERB (not necessarily with Rails), trim_mode: '-' removes one following newline:
    #  - the newline must be the first char after the > that ends the ERB expression
    #  - no following spaces are removed
    #  - only a single newline is removed
    erb = ERB.new template, trim_mode: '-'
    ctx = ArbitraryContextBinding.new(objects: @objects, modules: @modules, base_binding: @base_binding)
    erb.result ctx.get_binding
  end

  private

  # Collect methods from both objects and modules for delegation.
  # Ensures all public method names in @objects are unique; ancestors are not examined.
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

    # Module/class methods (singleton methods)
    @modules.each do |mod|
      mod.methods(false).each { |m| method_map[m] << mod }
    end

    # Define delegators and ensure only one method per name is defined
    method_map.each do |method_name, responders|
      case responders.size
      when 0 # This should not be possible
        # Do nothing because respond_to? will return false and a NameError will be raised if invoked as usual
      when 1 # Happy path: exactly one responder
        # define_singleton_method(method_name) do |*args, &block|
        #   responders.first.public_send(method_name, *args, &block)
        # end
        target = responders.first
        eval(<<~END_RUBY, @base_binding, __FILE__, __LINE__ + 1)
          def #{method_name}(*a, &b)
            ObjectSpace._id2ref(#{target.object_id}).public_send(:#{method_name}, *a, &b)
          end
        END_RUBY
      else # Error: more than one responder
        signatures = responders.map(&:to_s).join(', ')
        # Build the message safely outside the eval string
        error_message = "Ambiguous method '#{method_name}': multiple objects/modules (#{signatures}) respond"
        eval(<<~END_RUBY, @base_binding, __FILE__, __LINE__ + 1)
          def #{method_name}(*)
            raise AmbiguousMethodError, #{error_message.dump}
          end
        END_RUBY
      end
    end
  end

  # Make modules/classes accessible as constants inside ERB
  def define_module_constants!
    @modules.each do |mod|
      const_name = mod.name.split('::').last
      string = "Object.const_set('#{const_name}', mod) unless Object.const_defined?('#{const_name}')"
      eval(string, @base_binding, __FILE__, __LINE__ - 1)
    end
  end
end
