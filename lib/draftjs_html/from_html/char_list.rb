# frozen_string_literal: true

module DraftjsHtml
  class FromHtml < Nokogiri::XML::SAX::Document
    class CharList
      Char = Struct.new(:it, :entity, :atomic, keyword_init: true) do
        def atomic?
          self.atomic
        end
      end

      EntityRange = Struct.new(:entity, :start, :finish, keyword_init: true) do
        def range
          start..finish
        end

        def try_finish(index)
          self[:finish] ||= index
        end
      end

      attr_reader :chars

      def initialize(initial = [])
        @chars = initial.dup
      end

      def append(str, entity: nil)
        @chars << Char.new(it: "\n") if @chars.last&.atomic?

        @chars += str.chars.map { Char.new(it: _1, entity: entity) }
      end

      def append_char(char)
        @chars << char
      end

      def text
        @chars.map(&:it).join
      end

      def size
        @chars.size
      end

      def any?
        size > 0
      end

      def atomic?
        @chars.any? && @chars.all?(&:atomic?)
      end

      def each_line
        return to_enum(:each_line) unless block_given?

        line = self.class.new
        chars.each do |c|
          if c.it == "\n"
            yield  line
            line = self.class.new
            next
          end

          line.append_char(c)
        end

        yield line if line.any?
      end

      def apply_entity(range, entity)
        @chars[range].each { _1.entity = entity }
      end

      def append_atomic_entity(entity)
        append("\n") if @chars.any?
        append_char(Char.new(it: ' ', atomic: true, entity: entity))
      end

      def +(other)
        self.class.new(@chars + other.chars)
      end

      def entity_ranges
        current_entity = nil

        entity_ranges = @chars.each_with_object(Array.new).with_index do |(char, ranges), i|
          next if char.entity == current_entity

          current_entity = char.entity
          ranges.last&.try_finish(i - 1)
          ranges << EntityRange.new(entity: char.entity, start: i) if char.entity
        end

        entity_ranges.last&.try_finish(@chars.size - 1)
        entity_ranges
      end
    end
  end
end
