# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    class NullContent
      def blocks
        []
      end

      def entity_map
        {}
      end

      def find_entity(_key)
        nil
      end

      def attach_entity(_entity, _block, _range)
        nil
      end

      def to_raw
        ToRaw.new.convert(self)
      end

      def valid?
        false
      end

      def invalid?
        true
      end
    end
  end
end
