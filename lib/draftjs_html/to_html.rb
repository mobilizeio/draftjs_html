require_relative 'node'
require_relative 'html_depth'
require_relative 'html_defaults'
require_relative 'overrideable_map'

module DraftjsHtml
  class ToHtml
    def initialize(options)
      @options = ensure_options!(options)
      @document = Nokogiri::HTML::Builder.new(encoding: @options.fetch(:encoding, 'UTF-8'))
      @current_bidi_direction = CurrentBidiDirection.new
    end

    def convert(raw_draftjs)
      draftjs = Draftjs.parse(raw_draftjs)

      @document.html do |html|
        html.body do |body|
          @html_depth = HtmlDepth.new(body)

          draftjs.blocks.each do |block|
            @html_depth.apply(block)

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
      char_range.text = @options[:newline_squeezer].call(char_range.text.chomp)
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
      new_node = DraftjsHtml::Node.of(child).to_nokogiri(@document.doc)
      @current_bidi_direction.update(new_node.inner_text)
      nokogiri.parent['dir'] = 'rtl' if @current_bidi_direction.rtl?
      nokogiri.parent.add_child(new_node)
    end

    def block_element_for(block)
      return 'br' if block.blank?

      @options[:block_type_mapping].value_of!(block.type)
    end

    def style_element_for(style)
      @options[:inline_style_mapping].value_of!(style)
    end

    def try_apply_entity_to(draftjs, char_range)
      entity = draftjs.find_entity(char_range.entity_key)
      content = char_range.text
      if entity
        style_fn = @options[:entity_style_mappings].value_of(entity.type)
        content = style_fn.call(entity, Node.of(content), @document.parent)
      end

      content
    end

    def ensure_options!(opts)
      opts[:entity_style_mappings] = OverrideableMap.new(HtmlDefaults::ENTITY_CONVERSION_MAP)
        .with_overrides(opts[:entity_style_mappings])
        .with_default(HtmlDefaults::DEFAULT_ENTITY_STYLE_FN)
      opts[:block_type_mapping] = OverrideableMap.new(HtmlDefaults::BLOCK_TYPE_TO_HTML)
        .with_overrides(opts[:block_type_mapping])
      opts[:newline_squeezer] = opts[:squeeze_newlines] ? ->(text) { text.gsub(/(\n|\r\n)+/, "\n") } : ->(text) { text }
      opts[:inline_style_mapping] = OverrideableMap.new(HtmlDefaults::STYLE_MAP)
        .with_overrides(opts[:inline_style_mapping])
      opts[:inline_style_renderer] ||= ->(*) { nil }
      opts
    end
  end
end
