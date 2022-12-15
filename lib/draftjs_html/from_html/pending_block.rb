module DraftjsHtml
  class FromHtml < Nokogiri::XML::SAX::Document
    PendingBlock = Struct.new(:tagname, :attrs, :chars, :entities, :pending_entities, :parent_tagnames, :depth, keyword_init: true) do
      def self.from_tag(name, attrs, parent_tagnames, depth)
        self.new(
          tagname: name,
          attrs: attrs,
          entities: [],
          chars: CharList.new,
          pending_entities: [],
          depth: depth,
          parent_tagnames: parent_tagnames,
        )
      end

      def text_buffer
        self[:chars]
      end

      def character_offset
        text_buffer.size - 1
      end

      def flushable?
        %w[OPENING ol ul li table].include?(parent_tagnames.last) ||
          (parent_tagnames.last == 'div' && tagname != 'div')
      end

      def consume(other_pending_block)
        self.text_buffer += other_pending_block.text_buffer
        self.pending_entities += other_pending_block.pending_entities
        self.entities += other_pending_block.entities
      end

      def flush_to(draftjs)
        if text_buffer.any?
          text_buffer.each_line do |line|
            block_type = line.atomic? ? 'atomic' : block_name
            draftjs.typed_block(block_type, line.text, depth: [depth, 0].max)

            line.entity_ranges.each do |entity_range|
              entity = entity_range.entity
              draftjs.apply_entity entity[:type], entity_range.range, data: entity[:data], mutability: entity.fetch(:mutability, 'IMMUTABLE')
            end

            line.style_ranges.each do |style_range|
              draftjs.inline_style(style_range.style, style_range.range)
            end
          end
        end
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
    end
  end
end
