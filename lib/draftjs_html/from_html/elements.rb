module DraftjsHtml
  class FromHtml < Nokogiri::XML::SAX::Document
    INLINE_STYLE_ELEMENTS = HtmlDefaults::HTML_STYLE_TAGS_TO_STYLE.keys.freeze
    LIST_PARENT_ELEMENTS = %w[ol ul].freeze
    LIST_ITEM_ELEMENTS = %w[li].freeze
    INLINE_NON_STYLE_ELEMENTS = %w[a abbr cite font img output q samp span table thead tbody td time var].freeze
    BLOCK_CONTENT_ELEMENTS = %w[p dl h1 h2 h3 h4 h5 h6].freeze
    FLUSH_BOUNDARIES = %w[OPENING div ol ul li tr].freeze
  end
end
