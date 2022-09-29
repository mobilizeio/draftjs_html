# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    class Content
      def self.parse(raw)
        new(raw['blocks'].map { Block.parse(**_1) })
      end

      attr_reader :blocks

      def initialize(blocks)
        @blocks = blocks
      end
    end
  end
end