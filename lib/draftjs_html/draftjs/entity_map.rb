# frozen_string_literal: true

module DraftjsHtml
  module Draftjs
    class EntityMap < Hash
      def self.parse(raw)
        instance = new
        raw.each { |key, raw_entity| instance[key] = Entity.parse(raw_entity) }
        instance
      end
    end
  end
end
