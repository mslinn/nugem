module Nugem
  def self.camel_case(str)
    str.tr('-', '_')
      .split('_')
      .map(&:capitalize)
      .join
  end

  # @return Path to the generated gem
  def self.dest_root(out_dir, gem_name)
    File.expand_path "#{out_dir}/#{gem_name}"
  end

  def self.positional_parameters
    ARGV.reject { |x| x.start_with? '-' }
  end

  def self.run_me
    pp = ::Nugem.positional_parameters
    ::Nugem.help if pp.empty?
    gem_type = pp.first
    case gem_type
    when 'gem'
      nugem = Options.new
      nugem.parse_options
    when 'jekyll'
      nugem = JekyllOptions.new
      nugem.parse_options
    else
      puts "Error: unrecognized gem type '#{gem_type}'."
      exit 2
    end
  end

  def self.template_directory
    File.join gem_path(__FILE__), 'templates'
  end
end
