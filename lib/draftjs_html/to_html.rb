module DraftjsHtml
  class ToHtml
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

    def initialize
      @document = Nokogiri::HTML::Builder.new
    end

    def convert(raw_draftjs)
      @document.html do |html|
        html.body do |body|
          @previous_parent = body.parent

          raw_draftjs['blocks'].each do |block|
            new_wrapper_tag = BLOCK_TYPE_TO_HTML_WRAPPER[block['type']]
            if body.parent.name != new_wrapper_tag
              if new_wrapper_tag
                push_nesting(body, new_wrapper_tag)
              else
                pop_nesting(body)
              end
            end

            body.public_send(BLOCK_TYPE_TO_HTML.fetch(block['type']), block['text'])
          end
        end
      end

      @document.doc.css('body').first.children.to_html.strip
    end

    private

    def push_nesting(builder, tagname)
      node = create_child(builder, tagname)
      @previous_parent = builder.parent
      builder.parent = node
    end

    def pop_nesting(builder)
      builder.parent = @previous_parent
    end

    def create_child(builder, tagname)
      builder.parent.add_child(builder.doc.create_element(tagname))
    end
  end
end