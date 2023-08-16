# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    class Content
      def self.parse(raw)
        new(raw['blocks'].map { Block.parse(**_1) }, EntityMap.parse(raw['entityMap']))
      end

      attr_reader :blocks, :entity_map

      def initialize(blocks, entity_map)
        @blocks = blocks
        @entity_map = entity_map
      end

      def find_entity(key)
        entity_map[key]
      end

      def attach_entity(entity, block, range)
        new_key = new_entity_key
        entity_map[new_key] = entity
        block.add_entity(new_key, range)
      end

      def to_raw
        ToRaw.new.convert(self)
      end

      private

      def new_entity_key
        loop do
          key = SecureRandom.uuid
          break key unless entity_map.key?(key)
        end
      end
    end
  end
end
