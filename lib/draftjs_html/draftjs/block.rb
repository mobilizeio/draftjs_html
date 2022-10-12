# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    Block = Struct.new(:key, :text, :type, :depth, :inline_style_ranges, :raw_entity_ranges, keyword_init: true) do
      def self.parse(raw)
        new(
          key: raw['key'],
          text: raw['text'],
          type: raw['type'],
          depth: raw['depth'],
          inline_style_ranges: Array(raw['inlineStyleRanges']),
          raw_entity_ranges: Array(raw['entityRanges']),
        )
      end

      def length
        text.length
      end

      def blank?
        text.empty? && entity_ranges.empty?
      end

      def each_char
        return to_enum(:each_char) unless block_given?

        text.chars.map.with_index do |char, index|
          yield CharacterMeta.new(
            char: char,
            style_names: inline_styles.select { _1.range.cover?(index) }.map(&:name),
            entity_key: entity_ranges.select { _1.range.cover?(index) }.map(&:name).first,
          )
        end
      end

      CharRange = Struct.new(:text, :style_names, :entity_key, keyword_init: true)
      def each_range
        return to_enum(:each_range) unless block_given?

        current_styles = []
        current_entity = nil
        ranges = [CharRange.new(text: '', style_names: current_styles, entity_key: current_entity)]

        each_char.with_index do |char, index|
          if char.style_names != current_styles || char.entity_key != current_entity
            current_styles = char.style_names
            current_entity = char.entity_key
            yield(ranges.last) unless index == 0
            ranges << CharRange.new(text: '', style_names: current_styles, entity_key: current_entity)
          end

          ranges.last.text += char.char
        end

        yield ranges.last
      end

      alias plaintext text

      def inline_styles
        @inline_styles ||= inline_style_ranges.map do |raw|
          ApplicableRange.parse(raw['style'], raw)
        end
      end

      def entity_ranges
        @entity_ranges ||= raw_entity_ranges.map do |raw|
          ApplicableRange.parse(raw['key'].to_s, raw)
        end
      end

      def add_style(name, range)
        inline_styles << ApplicableRange.new(name: name, range: range)
      end
    end
  end
end
