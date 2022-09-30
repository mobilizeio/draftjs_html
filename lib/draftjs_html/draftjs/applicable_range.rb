# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    ApplicableRange = Struct.new(:name, :range, keyword_init: true) do
      def self.parse(name, raw)
        new(name: name, range: (raw['offset']..(raw['offset'] + raw['length'] - 1)))
      end

      def offset
        range.begin
      end

      def length
        range.size
      end
    end
  end
end
