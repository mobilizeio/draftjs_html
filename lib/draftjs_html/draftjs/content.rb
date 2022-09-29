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
    end
  end
end
