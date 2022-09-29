# frozen_string_literal: true

require_relative "draftjs_html/version"
require 'nokogiri'

module DraftjsHtml
  class Error < StandardError; end
  BLOCK_TYPE_TO_HTML = {
    'unstyled' => 'p',
    'paragraph' => 'p',
    'header-one' => 'h1',
    'header-two' => 'h2',
    'header-three' => 'h3',
    'header-four' => 'h4',
    'header-five' => 'h5',
    'header-six' => 'h6',
    'blockquote' => 'blockquote',
    'code-block' => 'code',
    'ordered-list-item' => 'li',
    'unordered-list-item' => 'li',
  }.freeze
  BLOCK_TYPE_TO_HTML_WRAPPER = {
    'code-block' => 'pre',
    'ordered-list-item' => 'ol',
    'unordered-list-item' => 'ul',
  }.freeze

  def self.to_html(raw_draftjs)
    document = Nokogiri::HTML::Builder.new do |html|
      html.body do |body|
        previous_parent = body.parent

        raw_draftjs['blocks'].each do |block|
          new_wrapper_tag = BLOCK_TYPE_TO_HTML_WRAPPER[block['type']]
          if body.parent.name != new_wrapper_tag
            if new_wrapper_tag
              node = create_child(body, new_wrapper_tag)
              previous_parent = body.parent
              body.parent = node
            else
              body.parent = previous_parent
            end
          end

          body.public_send(BLOCK_TYPE_TO_HTML.fetch(block['type']), block['text'])
        end
      end
    end.doc

    document.css('body').first.children.to_html.strip
  end

  private_class_method def self.create_child(builder, tagname)
    builder.parent.add_child(builder.doc.create_element(tagname))
  end
end
