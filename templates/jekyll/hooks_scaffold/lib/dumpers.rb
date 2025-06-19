# Methods to display Jekyll variable contents
module Dumpers
  # See https://github.com/jekyll/jekyll/blob/master/lib/jekyll/collection.rb
  #   attr_reader :site, :label, :metadata
  #   attr_writer :docs
  #   Metadata is a hash with at least these keys: output[Boolean], permalink[String]
  #   selected methods: collection_dir, directory, entries, exists?, files, filtered_entries, relative_directory
  def collection_as_string(collection, indent_spaces)
    indent = ' ' * indent_spaces
    result = <<~END_COLLECTION
      '#{collection.label}' collection within '#{collection.relative_directory}' subdirectory
        #{indent}Directory: #{collection.directory}
        #{indent}Does the directory exist and is it not a symlink if in safe mode? #{collection.exists?}
        #{indent}Collection_dir: #{collection.collection_dir}
        #{indent}Metadata: #{collection.metadata}
        #{indent}Static files: #{collection.files}
        #{indent}Filtered entries: #{collection.filtered_entries}
    END_COLLECTION
    result.chomp
  end

  def count_lines(string)
    return string.split("\n").length if string

    0
  end

  # Calling value.to_s blows up when a Jekyll::Excerpt
  # Error message is unrelated to the problem, makes it hard to track down
  # Be careful when converting values to string!
  def safe_to_s(value)
    return value.content if value.is_a? Jekyll::Excerpt

    value.to_s
  rescue StandardError => e
    e.message
  end

  # @param msg[String]
  # @param document[Jekyll:Document] https://github.com/jekyll/jekyll/blob/master/lib/jekyll/document.rb
  #   attr_reader :path, :extname, :collection, :type; :site is too big to dump here, we already have it anyway
  #   Selected methods: date
  def dump_document(logger, msg, document)
    attributes = attributes_as_string(document, %i[@path @extname @type])
    data = document.data.map { |k, v| "    #{k} = #{safe_to_s(v)}" }
    logger.info do
      <<~END_DOC
        #{msg}
          document dated #{document.date.to_date}:
            relative_path: #{document.relative_path}:
        #{attributes.join("\n")}
            Is it a draft? #{document.draft?}
            collection = #{collection_as_string(document.collection, 4)}
            content not dumped because it would likely be too long
            site not dumped also
            data:
          #{data.join("\n  ").rstrip.chomp}
      END_DOC
    end
  end

  # @param msg[String]
  # @param page[Jekyll:Page] https://github.com/jekyll/jekyll/blob/master/lib/jekyll/page.rb
  #   attr_accessor :basename, :content, :data, :ext, :name, :output, :pager, :site
  #   Selected methods: dir, excerpt, path, permalink, url
  def dump_page(logger, msg, page)
    attributes = attributes_as_string(page, %i[@basename @ext @name])
    # site = page.site available if you need it
    data = page.data.map { |k, v| "    #{k} = #{v}" }
    logger.info do
      <<~END_PAGE
        #{msg}\n  page at #{page.dir}:
        #{attributes.join("\n")}
            Is it HTML? #{page.html?}; is it an index? #{page.index?}
            Permalink: #{page.permalink}
            URL: #{page.url}
            content not dumped because it would likely be too long
            site not dumped also
            Excerpt: "#{page.excerpt}"
          data:
        #{data.join("\n")}
      END_PAGE
    end
  end

  # @param msg[String]
  # @param payload[Jekyll::Drops::UnifiedPayloadDrop] See https://github.com/jekyll/jekyll/blob/master/lib/jekyll/drops/unified_payload_drop.rb
  #    This is a mutable class.
  #    attr_accessor :content, :page, :layout, :paginator, :highlighter_prefix, :highlighter_suffix
  # payload.page is a Jekyll::Drops::DocumentDrop, which contains this payload,
  # see https://github.com/jekyll/jekyll/blob/master/lib/jekyll/drops/document_drop.rb
  def dump_payload(logger, msg, payload)
    result = <<~END_INFO
      #{msg} payload:
        content contains #{count_lines(payload.content)} lines.#{first_5_lines(payload.content)}
        layout = #{payload.layout}
        highlighter_prefix = #{payload.highlighter_prefix}
        paginator and site not dumped.
    END_INFO
    logger.info { result.chomp }
  end

  def first_5_lines(string)
    lines = string ? string.split("\n")[0..4] : []
    return "\n    first 5 lines:\n    #{lines.join("\n    ")}\n" if lines.length.positive?

    ''
  end

  # @param msg[String]
  # @param site[Jekyll::Site] https://github.com/jekyll/jekyll/blob/master/lib/jekyll/site.rb
  #   attr_accessor :baseurl, :converters, :data, :drafts, :exclude,
  #     :file_read_opts, :future, :gems, :generators, :highlighter,
  #     :include, :inclusions, :keep_files, :layouts, :limit_posts,
  #     :lsi, :pages, :permalink_style, :plugin_manager, :plugins,
  #     :reader, :safe, :show_drafts, :static_files, :theme, :time,
  #     :unpublished
  #   attr_reader :cache_dir, :config, :dest, :filter_cache, :includes_load_paths,
  #     :liquid_renderer, :profiler, :regenerator, :source
  def dump_site(logger, msg, site)
    logger.info do
      <<~END_INFO
        #{msg} site
        site is of type #{site.class}
        site.time = #{site.time}
      END_INFO
    end
    env = site.config['env']
    if env
      mode = env['JEKYLL_ENV']
      logger.info { "site.config['env']['JEKYLL_ENV'] = #{mode}" }
    else
      logger.info { "site.config['env'] is undefined" }
    end
    site.collections.each_key do |key|
      logger.info { "site.collections.#{key}" }
    end

    # key env contains all environment variables, quite verbose so output is reduced to just the 'env' key
    logger.info { "site.config has #{site.config.length} entries:" }
    site.config.sort.each { |key, value| logger.info { "  site.config.#{key} = '#{value}'" unless key == 'env' } }

    logger.info { "site.data has #{site.data.length} entries:" }
    site.data.sort.each { |key, value| logger.info { "  site.data.#{key} = '#{value}'" } }

    logger.info { "site.documents has #{site.documents.length} entries." }
    site.documents.each_key { |key| logger.info "site.documents.#{key}" }

    logger.info do
      <<~END_INFO
        site.keep_files has #{site.keep_files.length} entries.
        site.keep_files: #{site.keep_files.sort}
        site.pages has #{site.pages.length} entries.
      END_INFO
    end

    site.pages.each_key { |key| logger.info "site.pages.#{key}" }

    logger.info { "site.posts has #{site.posts.docs.length} entries." }
    site.posts.docs.each_key { |key| logger.info "site.posts.docs.#{key}" }

    logger.info { "site.tags has #{site.tags.length} entries." }
    site.tags.sort.each { |key, value| logger.info { "site.tags.#{key} = '#{value}'" } }
  end

  def attributes_as_string(object, attrs)
    attrs.map { |attr| "    #{attr.to_s.delete_prefix('@')} = #{object.instance_variable_get(attr)}" }
  end

  module_function :attributes_as_string, :collection_as_string, :count_lines, :dump_document, :dump_page,
                  :dump_payload, :dump_site, :first_5_lines, :safe_to_s
end
