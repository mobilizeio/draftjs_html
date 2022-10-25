module DraftjsHtml
  class FromHtml < Nokogiri::XML::SAX::Document
    class DepthStack
      def initialize
        @stack = []
        @nodes = []
        @list_depth = -1
        @style_stack = StyleStack.new
      end

      def push(tagname, attrs)
        @stack << PendingBlock.from_tag(tagname, attrs, @nodes.dup, @list_depth)
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
          pending_block.flush_to(draftjs, @style_stack)
          pending_block.apply_entities_to(draftjs)
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
          user_created_entity = conversion.call(pending_entity[:tagname], current_text_buffer[range], pending_entity[:attrs])
          next unless user_created_entity

          current.entities << user_created_entity.merge(start: range.begin, finish: range.end)
        end
      end

      def style_start(tagname)
        @style_stack.track_start(tagname, current_character_offset + 1)
      end

      def style_end(tagname)
        @style_stack.track_end(tagname, current_character_offset)
      end

      def flush_to(draftjs)
        current.flush_to(draftjs, @style_stack)
        current.apply_entities_to(draftjs)
      end

      def append_text(chars)
        current.text_buffer << chars unless chars.empty?
      end

      private

      def current_text_buffer
        current.text_buffer.join
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
