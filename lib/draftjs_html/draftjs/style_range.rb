# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    StyleRange = Struct.new(:name, :range, keyword_init: true) do
      def self.parse(name, raw)
        new(name: name, range: (raw['offset']..(raw['offset'] + raw['length'] - 1)))
      end
    end
  end
end
