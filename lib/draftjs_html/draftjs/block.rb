# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    Block = Struct.new(:key, :text, :type, keyword_init: true) do
      def self.parse(raw)
        new(key: raw['key'], text: raw['text'], type: raw['type'])
      end

      def length
        text.length
      end

      alias plaintext text
    end
  end
end