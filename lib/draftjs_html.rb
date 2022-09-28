# frozen_string_literal: true

require_relative "draftjs_html/version"

module DraftjsHtml
  class Error < StandardError; end

  def self.to_html(raw_draftjs)
    "<p>#{raw_draftjs.dig('blocks', 0, 'text')}</p>"
  end
end
