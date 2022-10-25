module DraftjsHtml
  class FromHtml < Nokogiri::XML::SAX::Document
    PendingBlock = Struct.new(:tagname, :attrs, :chars, :entities, :pending_entities, :parent_tagnames, :depth, keyword_init: true) do
      def self.from_tag(name, attrs, parent_tagnames, depth)
        self.new(
          tagname: name,
          attrs: attrs,
          entities: [],
          chars: [],
          pending_entities: [],
          depth: depth,
          parent_tagnames: parent_tagnames,
        )
      end

      def text_buffer
        self[:chars]
      end

      def clear_text_buffer
        self[:chars] = []
      end

      def character_offset
        text_buffer.join.length - 1
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

      def flush_to(draftjs, styles)
        if text_buffer.any?
          chars.join.lines.each do |line|
            draftjs.typed_block(block_name, line.strip, depth: [depth, 0].max)
          end

          styles.each do |descriptor|
            finish = descriptor[:finish] || character_offset
            draftjs.inline_style(descriptor[:style], descriptor[:start]..finish)
          end
        end

        clear_text_buffer
        styles.clear_finished
      end

      def apply_entities_to(draftjs)
        Array(entities).each do |entity|
          range = entity[:start]..entity[:finish]
          if entity[:atomic]
            draftjs.typed_block('atomic', ' ', depth: [depth, 0].max)
            range = 0..1
          elsif range.size < 1
            draftjs.typed_block('atomic', ' ', depth: [depth, 0].max) unless draftjs.has_blocks?
            range = (range.begin..range.end + 1)
          end

          draftjs.apply_entity entity[:type], range, data: entity[:data], mutability: entity.fetch(:mutability, 'IMMUTABLE')
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
