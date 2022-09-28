# frozen_string_literal: true

require_relative "draftjs_html/version"
require 'nokogiri'

module DraftjsHtml
  class Error < StandardError; end

  def self.to_html(raw_draftjs)
    document = Nokogiri::HTML::Builder.new do |html|
      html.body do |body|
        raw_draftjs['blocks'].each do |block|
          body.p block['text']
        end
      end
    end.to_html

    Nokogiri::HTML(document).css('body').first.children.to_html.strip
  end
end
