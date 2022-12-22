module DraftjsHtml
  class FromHtml < Nokogiri::XML::SAX::Document
    class DepthStack
      def initialize(options)
        @stack = []
        @nodes = []
        @list_depth = -1
        @active_styles = []
        @options = options
      end

      def push(tagname, attrs)
        @stack << PendingBlock.from_tag(tagname, attrs, @nodes.dup, @list_depth, options: @options)
        track_block_node(tagname)
      end

      def push_parent(tagname, attrs)
        @list_depth += 1
        track_block_node(tagname)
      end

      def pop_parent(tagname, draftjs)
        @nodes.pop
        blocks = []
        while current.depth >= 0
          blocks << @stack.pop
          @nodes.pop
        end
        blocks.reverse_each do |pending_block|
          pending_block.flush_to(draftjs)
        end
        @list_depth -= 1
      end

      def pop(draftjs)
        return if @stack.empty?
        return if inside_parent?

        if @nodes.last == current.tagname && current.flushable?
          flush_to(draftjs)
        elsif @stack[-2]
          @stack[-2].consume(current)
        end

        @stack.pop
        @nodes.pop
      end

      def create_pending_entity(tagname, attrs)
        current.pending_entities << { tagname: tagname, start: current_character_offset + 1, attrs: attrs }
      end

      def convert_pending_entities(conversion)
        while current.pending_entities.any?
          pending_entity = current.pending_entities.pop
          range = pending_entity[:start]..current_character_offset
          content = current_text_buffer[range]
          user_created_entity = conversion.call(pending_entity[:tagname], content, pending_entity[:attrs])
          next unless user_created_entity

          if content == '' && !user_created_entity[:atomic]
            current.text_buffer.append(' ', entity: user_created_entity)
          elsif content == '' && user_created_entity[:atomic]
            current.text_buffer.append_atomic_entity(user_created_entity)
          else
            current.text_buffer.apply_entity(range, user_created_entity)
          end
        end
      end

      def style_start(tagname)
        @active_styles += [DraftjsHtml::HtmlDefaults::HTML_STYLE_TAGS_TO_STYLE[tagname]]
      end

      def style_end(tagname)
        @active_styles.delete_at(@active_styles.index(DraftjsHtml::HtmlDefaults::HTML_STYLE_TAGS_TO_STYLE[tagname]))
      end

      def flush_to(draftjs)
        current.flush_to(draftjs)
      end

      def append_text(chars)
        current.text_buffer.append(chars, styles: @active_styles) unless chars.empty?
      end

      private

      def current_text_buffer
        current.text_buffer.text
      end

      def current_character_offset
        current.character_offset
      end

      def track_block_node(name)
        @nodes << name
      end

      def inside_parent?
        (FromHtml::LIST_PARENT_ELEMENTS & @nodes).any?
      end

      def current
        @stack.last
      end
    end
  end
end
