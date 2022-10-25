require 'stringio'
require_relative 'html_defaults'
require_relative 'from_html/elements'
require_relative 'from_html/style_stack'
require_relative 'from_html/pending_block'
require_relative 'from_html/depth_stack'

module DraftjsHtml
  class FromHtml < Nokogiri::XML::SAX::Document

    def initialize(options = {})
      @draftjs = Draftjs::RawBuilder.new
      @parser = Nokogiri::HTML4::SAX::Parser.new(self)
      @depth_stack = DepthStack.new
      @options = ensure_options!(options.dup)
    end

    def convert(raw_html)
      convert_io(StringIO.new(raw_html))
    end

    def convert_io(html_io)
      @parser.parse(html_io)
      @draftjs.to_h
    end

    def characters(str)
      content = strip_unnecessary_trailing_space(str)
      @depth_stack.append_text(content)
    end

    def end_element(name)
      track_pending_entity_end(name)

      case name
      when 'br' then return
      when 'html', 'body', *FromHtml::INLINE_NON_STYLE_ELEMENTS
      when *FromHtml::INLINE_STYLE_ELEMENTS
        track_inline_style_end(name)
      when *FromHtml::LIST_PARENT_ELEMENTS
        @depth_stack.pop_parent(name, @draftjs)
      else
        @depth_stack.pop(@draftjs)
      end
    end

    def start_element(name, attrs = [])
      attributes = Hash[attrs]

      case name
      when 'br'
        @depth_stack.append_text("\n")
      when 'html', 'body', *FromHtml::INLINE_NON_STYLE_ELEMENTS
      when *FromHtml::INLINE_STYLE_ELEMENTS
        track_inline_style_start(name)
      when *FromHtml::LIST_PARENT_ELEMENTS
        @depth_stack.push_parent(name, attrs)
      else
        @depth_stack.push(name, attributes)
      end

      track_pending_entity_start(name, attributes)
    end

    def start_document
      @depth_stack.push('OPENING', {})
    end

    def end_document
      @depth_stack.flush_to(@draftjs)
    end

    private

    def track_inline_style_start(tagname)
      @depth_stack.style_start(tagname)
    end

    def track_inline_style_end(tagname)
      @depth_stack.style_end(tagname)
    end

    def strip_unnecessary_trailing_space(str)
      str
        .gsub(/(\n+[[:space:]]*$)|(^\n+)/, '')
        .gsub(/(^[[:space:]]+$)/, ' ')
    end

    def track_pending_entity_start(tagname, attrs)
      @depth_stack.create_pending_entity(tagname, attrs)
    end

    def track_pending_entity_end(name)
      @depth_stack.convert_pending_entities(@options[:node_to_entity])
    end

    def ensure_options!(opts)
      opts[:node_to_entity] ||= ->(tagname, _content, attrs) {
        case tagname
        when 'a' then { type: 'LINK', mutability: 'MUTABLE', data: attrs }
        when 'img' then { type: 'IMAGE', mutability: 'IMMUTABLE', atomic: true, data: attrs }
        end
      }
      opts
    end
  end
end
