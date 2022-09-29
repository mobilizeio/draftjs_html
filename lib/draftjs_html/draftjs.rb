# frozen_string_literal: true

require_relative 'draftjs/content'
require_relative 'draftjs/block'

module DraftjsHtml
  module Draftjs
    def self.parse(raw)
      Content.parse(raw)
    end
  end
end