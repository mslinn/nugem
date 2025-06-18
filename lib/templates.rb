require 'erb'

# Methods to mix in to other modules or classes for handling ERB templates.
# This module provides methods to manage templates, including loading,
# rendering, and writing them to specified paths.
#
# @example
#   include ERBTemplates
#   templates.each do |template|
#     puts template.render
#   end
module ERBTemplates
  # lib/helper/jekyll_plugin_helper_attribution.rb defines a method called current_spec,
  # which returns the Gem::Specification for the gem that contains the code that invoked the method.
  # See https://github.com/mslinn/jekyll_plugin_support/blob/v3.1.0/lib/helper/jekyll_plugin_helper_attribution.rb#L4-L20
  #
  # The method is explained in detail here:
  # - https://www.mslinn.com/ruby/6550-gem-navel.html#self_discovery
  # The method is contained in the JekyllSupport module, which is part of the jekyll_plugin_support gem.
  # This is unusual: the instead of `require 'jekyll_plugin_support'`, the gem source code is obtained and the class-level method is executed.
  #
  # The method called current_spec, below, is used to determine the Gem::Specification for the gem that contains the code
  # that invoked the method. This is useful for locating the templates directory for the gem.
  #
  # We call it as described in the article:
  # - https://www.notonlycode.org/12-ways-to-call-a-method-in-ruby/#:~:text=12%3A%20using%20%22source%22%20and%20%22instance_eval%22
  def current_spec
    # The jekyll_plugin_support gem provides helper methods for Jekyll plugins.
    # One of the methods is `current_spec`, which returns the Gem::Specification for the gem that contains the code that invoked the method.
    # We would like to load the jekyll_plugin_support gem as follows:
    # require 'jekyll_plugin_support/helper/jekyll_plugin_helper_attribution'
    # However, this does not work because the gem raises an `Exception` when loaded without the Jekyll configuration file.
    # So we `require` the gem, catch the initialization error, and then call the `::JekyllSupport::JekyllPluginHelper.current_spec` method.
    begin
      require 'jekyll_plugin_support'
    rescue Errno::ENOENT # rubocop:disable Lint/SuppressedException
    rescue StandardError => e
      puts e.message
    end
    ::JekyllSupport::JekyllPluginHelper.current_spec __FILE__
  end

  # @return [String] Path to the templates directory, or the specified subdirectory within it.
  def template_directory(subdir = '')
    File.join current_spec.full_gem_path, 'templates', subdir
  end

  # @return [Array<String>] List of all files in the templates directory
  def template_files(subdir = '')
    Dir
      .entries(template_directory(subdir))
      .select { |f| File.file? f }
  end

  class Template
    attr_reader :name, :path

    def initialize(binding, offset, relative_path)
      raise ArgumentError, 'Binding must be a valid binding object' unless binding.is_a?(Binding)
      raise ArgumentError, 'offset must be a non-empty string' unless offset.is_a?(String) && !offset.empty?
      raise ArgumentError, 'relative_path must be a non-empty string' unless relative_path.is_a?(String) && !relative_path.empty?

      @binding = binding
      @name = File.basename relative_path
      @offset = offset
      @relative_path = relative_path
      @requires_expansion = relative_path.end_with? '.tt'
      @source_path = File.join(template_directory, @offset, @relative_path)

      raise ArgumentError, "Path '#{@source_path}' does not exist" unless File.file?(@source_path)
    end

    def render
      content = File.read(File.join(@offset, @relative_path))
      if @requires_expansion
        ERB.new(content).result(@binding)
      else
        content
      end
    rescue Errno::ENOENT => e
      raise "Template file not found: #{@relative_path}. Error: #{e.message}"
    rescue StandardError => e
      raise "Error rendering template #{@relative_path}: #{e.message}"
    end

    def write(target_path)
      destination = File.join(target_path, @relative_path)
      File.write(destination, render)
    rescue Errno::EACCES => e
      raise "Permission denied when writing expanded template to #{destination}. Error: #{e.message}"
    rescue StandardError => e
      raise "Error writing expanded template to #{destination}: #{e.message}"
    end

    def ==(other)
      other.is_a?(Template) && @path == other.path
    end
  end
end
