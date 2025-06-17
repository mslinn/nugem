module Nugem
  class JekyllOptions < Options
    def initialize
      super

      @attribute_name = 'jekyll'

      jekyll_default_options = {
        gem_type: :jekyll,
      }
      @default_options = super.default_options.merge jekyll_default_options
    end

    def parse_options
      super.parse_options
      parse_positional_parameters
    end
  end
end
