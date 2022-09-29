# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    Entity = Struct.new(:type, :mutability, :data, keyword_init: true) do
      def self.parse(raw)
        new(
          type: raw['type'],
          mutability: raw['mutability'],
          data: raw['data'],
        )
      end
    end
  end
end
