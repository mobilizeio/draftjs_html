require_relative 'node'

module DraftjsHtml
  class ToHtml
    BLOCK_TYPE_TO_HTML = {
      'unstyled' => 'p',
      'paragraph' => 'p',
      'header-one' => 'h1',
      'header-two' => 'h2',
      'header-three' => 'h3',
      'header-four' => 'h4',
      'header-five' => 'h5',
      'header-six' => 'h6',
      'blockquote' => 'blockquote',
      'code-block' => 'code',
      'ordered-list-item' => 'li',
      'unordered-list-item' => 'li',
      'atomic' => 'figure',
    }.freeze
    BLOCK_TYPE_TO_HTML_WRAPPER = {
      'code-block' => 'pre',
      'ordered-list-item' => 'ol',
      'unordered-list-item' => 'ul',
    }.freeze
    STYLE_MAP = {
      'BOLD' => 'b',
      'ITALIC' => 'i',
      'STRIKETHROUGH' => 'del',
      'UNDERLINE' => 'u',
    }.freeze

    DEFAULT_ENTITY_STYLE_FN = ->(_entity, chars, _doc) { chars }
    ENTITY_ATTRIBUTE_NAME_MAP = {
      'className' => 'class',
      'url' => 'href',
    }.freeze
    ENTITY_CONVERSION_MAP = {
      'LINK' => ->(entity, content, *) {
        attributes = entity.data.slice('url', 'rel', 'target', 'title', 'className').each_with_object({}) do |(attr, value), h|
          h[ENTITY_ATTRIBUTE_NAME_MAP.fetch(attr, attr)] = value
        end

        DraftjsHtml::Node.new('a', attributes, content)
      },
      'IMAGE' => ->(entity, *) {
        attributes = entity.data.slice('src', 'alt', 'className', 'width', 'height').each_with_object({}) do |(attr, value), h|
          h[ENTITY_ATTRIBUTE_NAME_MAP.fetch(attr, attr)] = value
        end

        DraftjsHtml::Node.new('img', attributes)
      }
    }.freeze

    def initialize(options)
      @options = ensure_options!(options)
      @document = Nokogiri::HTML::Builder.new(encoding: @options.fetch(:encoding, 'UTF-8'))
      @current_depth = 0
    end

    def convert(raw_draftjs)
      draftjs = Draftjs.parse(raw_draftjs)

      @document.html do |html|
        html.body do |body|
          @previous_parents = [body.parent]

          draftjs.blocks.each do |block|
            ensure_nesting_depth(block, body)

            body.public_send(block_element_for(block)) do |block_body|
              block.each_range do |char_range|
                squeeze_newlines(char_range)
                content = try_apply_entity_to(draftjs, char_range)

                apply_styles_to(block_body, char_range.style_names, Node.of(content))
              end
            end
          end
        end
      end

      @document.doc.css('body').first.children.to_html.strip
    end

    private

    def squeeze_newlines(char_range)
      char_range.text = @options[:newline_squeezer].call(char_range.text)
    end

    def ensure_nesting_depth(block, body)
      new_wrapper_tag = BLOCK_TYPE_TO_HTML_WRAPPER[block.type]
      if body.parent.name != new_wrapper_tag || block.depth != @current_depth
        if @current_depth < block.depth
          push_depth(body, new_wrapper_tag)
        elsif @current_depth > block.depth
          pop_depth(body, times: @current_depth - block.depth)
          pop_nesting(body) unless new_wrapper_tag
        elsif new_wrapper_tag
          push_nesting(body, new_wrapper_tag)
        elsif @previous_parents.size > 1
          pop_nesting(body)
        end
        @current_depth = block.depth
      end
    end

    def apply_styles_to(html, style_names, child)
      return append_child(html, child) if style_names.empty?

      custom_render_content = @options[:inline_style_renderer].call(style_names, child, @document.parent)
      return append_child(html, custom_render_content) if custom_render_content

      style, *rest = style_names
      html.public_send(style_element_for(style)) do |builder|
        apply_styles_to(builder, rest, child)
      end
    end

    def append_child(nokogiri, child)
      nokogiri.parent.add_child(DraftjsHtml::Node.of(child).to_nokogiri(@document.doc))
    end

    def block_element_for(block)
      return 'br' if block.blank?

      @options[:block_type_mapping].fetch(block.type)
    end

    def style_element_for(style)
      @options[:inline_style_mapping][style]
    end

    def try_apply_entity_to(draftjs, char_range)
      entity = draftjs.find_entity(char_range.entity_key)
      content = char_range.text
      if entity
        style_fn = (@options[:entity_style_mappings][entity.type] || DEFAULT_ENTITY_STYLE_FN)
        content = style_fn.call(entity, Node.of(content), @document.parent)
      end

      content
    end

    def push_depth(builder, tagname)
      @previous_parents << builder.parent
      builder.parent = builder.parent.last_element_child
      push_nesting(builder, tagname)
    end

    def push_nesting(builder, tagname)
      node = create_child(builder, tagname)
      @previous_parents << builder.parent
      builder.parent = node
    end

    def pop_depth(builder, times:)
      times.times do
        pop_nesting(builder)
        pop_nesting(builder)
      end
    end

    def pop_nesting(builder)
      builder.parent = @previous_parents.pop
    end

    def create_child(builder, tagname)
      builder.parent.add_child(builder.doc.create_element(tagname))
    end

    def ensure_options!(opts)
      opts[:entity_style_mappings] = ENTITY_CONVERSION_MAP.merge(opts[:entity_style_mappings] || {}).transform_keys(&:to_s)
      opts[:block_type_mapping] = BLOCK_TYPE_TO_HTML.merge(opts[:block_type_mapping] || {})
      opts[:newline_squeezer] = opts[:squeeze_newlines] ? ->(text) { text.gsub(/(\n|\r\n)+/, "\n") } : ->(text) { text }
      opts[:inline_style_mapping] = STYLE_MAP.merge(opts[:inline_style_mapping] || {}).transform_keys(&:to_s)
      opts[:inline_style_renderer] ||= ->(*) { nil }
      opts
    end
  end
end
