# frozen_string_literal: true

require_relative "draftjs_html/version"
require 'nokogiri'

module DraftjsHtml
  class Error < StandardError; end

  def self.to_html(raw_draftjs)
    document = Nokogiri::HTML::Builder.new do |html|
      html.body do |body|
        raw_draftjs['blocks'].each do |block|
          body.public_send(element_for(block['type']), block['text'])
        end
      end
    end.to_html

    Nokogiri::HTML(document).css('body').first.children.to_html.strip
  end

  private_class_method def self.element_for(type)
    {
      'unstyled' => 'p',
      'paragraph' => 'p',
      'header-one' => 'h1',
      'header-two' => 'h2',
      'header-three' => 'h3',
      'header-four' => 'h4',
      'header-five' => 'h5',
      'header-six' => 'h6',
      'blockquote' => 'blockquote',
    }.fetch(type)
  end
end
