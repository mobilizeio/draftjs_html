module DraftjsHtml
  module HtmlDefaults
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
      'atomic' => 'figure',
    }.freeze

    STYLE_MAP = {
      'BOLD' => 'b',
      'ITALIC' => 'i',
      'STRIKETHROUGH' => 'del',
      'UNDERLINE' => 'u',
    }.freeze

    ENTITY_ATTRIBUTE_NAME_MAP = {
      'className' => 'class',
      'url' => 'href',
    }.freeze

    DEFAULT_ENTITY_STYLE_FN = ->(_entity, chars, _doc) { chars }

    ENTITY_CONVERSION_MAP = {
      'LINK' => ->(entity, content, *) {
        attributes = entity.data.slice('url', 'rel', 'target', 'title', 'className').each_with_object({}) do |(attr, value), h|
          h[ENTITY_ATTRIBUTE_NAME_MAP.fetch(attr, attr)] = value
        end

        DraftjsHtml::Node.new('a', attributes, content)
      },
      'IMAGE' => ->(entity, *) {
        attributes = entity.data.slice('src', 'alt', 'className', 'width', 'height').each_with_object({}) do |(attr, value), h|
          h[ENTITY_ATTRIBUTE_NAME_MAP.fetch(attr, attr)] = value
        end

        DraftjsHtml::Node.new('img', attributes)
      }
    }.freeze
  end
end