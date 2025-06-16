module Nugem
  class Cli < Thor
    include Thor::Actions

    def self.combinations(params)
      (0..params.length).flat_map do |n|
        params.combination(n).map do |param|
          next [] if param.empty?

          param.flat_map do |p|
            name = p.first
            type = p[1]
            case type
            when 'boolean' then name
            when 'string' then "#{name}='somevalue'"
            when 'numeric' then "#{name}=1234"
            else "#{name} has unknown type: #{type}"
            end
          end
        end
      end
    end

    def self.add_demo_example(tag, params, tag_type = :tag)
      last_tag = ''
      examples = combinations(params).map do |option|
        options = option.join ' '
        label = options.empty? ? ' (invoked without parameters)' : options
        close_tag = case tag_type
                    when :tag then ''
                    when :block then <<~END_BLOCK
                      \nThis is line 1 of the block content.<br>
                      This is line 2.
                      {% end#{tag} %}
                    END_BLOCK
                    end
        example = <<~END_EX
          <!-- #region #{tag} #{label} -->
          <h3 id="#{tag}" class="code">#{tag} #{label}</h3>
          {% #{tag} #{options} %}#{close_tag}
          <!-- endregion -->
        END_EX
        if tag == last_tag
          example
        else
          last_tag = tag
          "<h2 id=\"tag_#{tag}\" class='code'>#{tag}</h2>\n" + example
        end
      end
      examples.join("\n\n")
    end

    def self.add_filter_example(filter_name, trailing_params)
      <<~END_EX
        <h2 id="filter_#{filter_name}" class='code'>#{filter_name}</h2>
        {{ "TODO: Provide filter input here" | #{filter_name}#{trailing_params} }}
      END_EX
    end
  end
end
