require 'erb'

module Templates
  # @return [String] Path to the templates directory
  def template_directory
    File.join(File.dirname(__FILE__), 'templates')
  end

  # @return [Array<String>] List of all template files in the templates directory
  def template_files
    Dir
      .glob(File.join(template_directory, '*'))
      .select { |f| File.file?(f) }
  end

  # @return [Hash] A hash mapping template names to their file paths
  def template_hash
    template_files.each_with_object({}) do |file, hash|
      hash[file] = file
    end
  end

  # @return [Array<Template>] List of Template objects for each template file
  def templates
    template_hash.map { |name, path| Template.new(name, path) }
  end

  class Template
    attr_reader :name, :path

    def initialize(binding, path)
      raise ArgumentError, 'Binding must be a valid binding object' unless binding.is_a?(Binding)
      raise ArgumentError, 'Name must be a non-empty string' unless name.is_a?(String) && !name.empty?
      raise ArgumentError, 'Path must be a non-empty string' unless path.is_a?(String) && !path.empty?
      raise ArgumentError, 'Path must point to a valid file' unless File.file?(path)

      @binding = binding
      @name = File.basename path
      @path = path
      @requires_expansion = path.end_with? '.tt'
    end

    def render
      content = File.read(@path)
      if @requires_expansion
        ERB.new(content).result(@binding)
      else
        content
      end
    rescue Errno::ENOENT => e
      raise "Template file not found: #{@path}. Error: #{e.message}"
    rescue StandardError => e
      raise "Error rendering template #{@path}: #{e.message}"
    end

    def to_s
      "#{@name} (#{@path})"
    end

    def write(target_path)
      destination = "#{target_path}/#{@path}"
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
