# frozen_string_literal: true

require_relative 'draftjs/content'
require_relative 'draftjs/character_meta'
require_relative 'draftjs/applicable_range'
require_relative 'draftjs/block'
require_relative 'draftjs/entity_map'
require_relative 'draftjs/entity'
require_relative 'draftjs/to_raw'
require_relative 'draftjs/raw_builder'

module DraftjsHtml
  module Draftjs
    def self.parse(raw)
      Content.parse(raw)
    end
  end
end
