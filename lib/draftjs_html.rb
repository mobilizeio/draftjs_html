# frozen_string_literal: true

require_relative "draftjs_html/version"
require 'nokogiri'
require_relative 'draftjs_html/to_html'

module DraftjsHtml
  class Error < StandardError; end

  def self.to_html(raw_draftjs)
    ToHtml.new.convert(raw_draftjs)
  end
end
