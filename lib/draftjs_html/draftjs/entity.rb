# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    Entity = Struct.new(:type, :mutability, :data, :key, keyword_init: true) do
      def self.parse(raw, key: nil)
        new(
          key: key,
          type: raw['type'],
          mutability: raw['mutability'],
          data: raw['data'],
        )
      end
    end
  end
end
