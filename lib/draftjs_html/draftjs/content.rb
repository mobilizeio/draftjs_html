# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    class Content
      def self.parse(raw)
        validate_raw_input!(raw)
        new(raw['blocks'].map { Block.parse(**_1) }, EntityMap.parse(raw['entityMap']))
      end

      def self.validate_raw_input!(raw)
        raise InvalidRawDraftjs.new('raw cannot be nil') if raw.nil?
        raise InvalidRawDraftjs.new('raw must contain "blocks" array') unless raw['blocks'].is_a?(Array)
        raise InvalidRawDraftjs.new('raw must contain "entityMap" hash') unless raw['entityMap'].is_a?(Hash)
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

      def valid?
        self.class.validate_raw_input!({ 'blocks' => blocks, 'entityMap' => entity_map })
        true
      rescue
        false
      end

      def invalid?
        !valid?
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
