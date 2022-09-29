# frozen_string_literal: true

require_relative 'draftjs/content'
require_relative 'draftjs/character_meta'
require_relative 'draftjs/style_range'
require_relative 'draftjs/block'

module DraftjsHtml
  module Draftjs
    def self.parse(raw)
      Content.parse(raw)
    end
  end
end