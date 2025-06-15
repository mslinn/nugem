module Nugem
  def self.camel_case(str)
    str.tr('-', '_')
      .split('_')
      .map(&:capitalize)
      .join
  end

  def self.expand_env(str)
    str.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) do
      ENV.fetch(Regexp.last_match(1), nil)
    end
  end

  # The following methods are not required at present ... but they might be needed one day, so not deleting yet

  # @param file must be a fully qualified file name
  # @return Gem::Specification of gem that file points into, or nil if not called from a gem
  def self.current_spec(file)
    return nil unless File.file?(file)

    searcher = if Gem::Specification.respond_to?(:find)
                 Gem::Specification
               elsif Gem.respond_to?(:searcher)
                 Gem.searcher.init_gemspecs
               end

    searcher&.find do |spec|
      file.start_with? spec.full_gem_path
    end
  end

  def self.gem_path(file)
    spec = current_spec(file)
    spec&.full_gem_path
  end

  def self.template_directory
    File.join gem_path(__FILE__), 'templates'
  end
end
