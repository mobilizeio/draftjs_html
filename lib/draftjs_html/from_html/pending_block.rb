module DraftjsHtml
  class FromHtml < Nokogiri::XML::SAX::Document
    PendingBlock = Struct.new(:tagname, :attrs, :chars, :entities, :pending_entities, :parent_tagnames, :depth, :options, keyword_init: true) do
      def self.from_tag(name, attrs, parent_tagnames, depth, options: {})
        self.new(
          tagname: name,
          attrs: attrs,
          entities: [],
          chars: CharList.new,
          pending_entities: [],
          depth: depth,
          parent_tagnames: parent_tagnames,
          options: options
        )
      end

      def text_buffer
        self[:chars]
      end

      def character_offset
        text_buffer.size - 1
      end

      def flushable?
        FLUSH_BOUNDARIES.include?(parent_tagnames.last)
      end

      def consume(other_pending_block)
        self.text_buffer += other_pending_block.text_buffer
        self.pending_entities += other_pending_block.pending_entities
        self.entities += other_pending_block.entities
      end

      def flush_to(draftjs)
        text_buffer.each_line do |line|
          block_type = line.atomic? ? 'atomic' : block_name
          next unless should_flush_line?(line)

          draftjs.typed_block(block_type, line.text, depth: [depth, 0].max)

          line.entity_ranges.each do |entity_range|
            entity = entity_range.entity
            draftjs.apply_entity entity[:type], entity_range.range, data: entity[:data], mutability: entity.fetch(:mutability, 'IMMUTABLE')
          end

          line.style_ranges.each do |style_range|
            draftjs.inline_style(style_range.style, style_range.range)
          end
        end

        self.text_buffer = CharList.new
      end

      def block_name
        stack = parent_tagnames.last == 'li' ? parent_tagnames.last(2) : parent_tagnames.last(1)
        return 'ordered-list-item' if stack.first == 'ol'
        return 'unordered-list-item' if stack.first == 'ul'

        DraftjsHtml::HtmlDefaults::BLOCK_TYPE_TO_HTML.invert.fetch(tagname, 'unstyled')
      end

      private

      def text_buffer=(other)
        self[:chars] = other
      end

      def should_flush_line?(chars)
        return true if chars.atomic?
        return true unless options[:squeeze_whitespace_blocks]

        options[:squeeze_whitespace_blocks] && chars.more_than_whitespace?
      end
    end
  end
end
