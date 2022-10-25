# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    class ToRaw
      def convert(parsed)
        {
          'blocks' => parsed.blocks.map(&method(:convert_block)),
          'entityMap' => convert_entity_map(parsed.entity_map),
        }
      end

      private

      def convert_block(block)
        {
          'key' => block.key,
          'text' => block.text,
          'type' => block.type,
          'depth' => block.depth,
          'inlineStyleRanges' => block.inline_styles.map { { 'style' => _1.name, 'offset' => _1.offset, 'length' => _1.length } },
          'entityRanges' => block.entity_ranges.map { { 'key' => _1.name, 'offset' => _1.offset, 'length' => _1.length } },
        }
      end

      def convert_entity_map(entity_map)
        entity_map.each_with_object({}) do |(key, entity), h|
          h[key] = {
            'type' => entity.type,
            'mutability' => entity.mutability,
            'data' => entity.data,
          }
        end
      end
    end
  end
end
