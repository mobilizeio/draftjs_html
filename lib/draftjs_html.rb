# frozen_string_literal: true

require_relative "draftjs_html/version"

module DraftjsHtml
  class Error < StandardError; end

  def self.to_html(raw_draftjs)
    raw_draftjs['blocks'].map { "<p>#{_1['text']}</p>" }.join("\n")
  end
end
