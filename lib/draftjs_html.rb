# frozen_string_literal: true

require_relative "draftjs_html/version"
require 'nokogiri'
require_relative 'draftjs_html/draftjs'
require_relative 'draftjs_html/current_bidi_direction'
require_relative 'draftjs_html/to_html'
require_relative 'draftjs_html/from_html'

module DraftjsHtml
  class Error < StandardError; end

  def self.to_html(raw_draftjs, options: {})
    ToHtml.new(options).convert(raw_draftjs)
  end

  def self.from_html(html_str, options: {})
    FromHtml.new(options).convert(html_str)
  end
end
