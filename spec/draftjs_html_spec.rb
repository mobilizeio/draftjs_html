# frozen_string_literal: true

RSpec.describe DraftjsHtml do
  it "has a version number" do
    expect(DraftjsHtml::VERSION).not_to be nil
  end

  it 'generates valid HTML from the most basic of DraftJS' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'Hello world!'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq '<p>Hello world!</p>'
  end

  it 'supports generating multiple blocks of plain text' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'Hello world!'
      text_block 'Winter is coming.'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq "<p>Hello world!</p>\n<p>Winter is coming.</p>"
  end

  it 'does not mangle text with special characters' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block '❄️ is coming'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq "<p>❄️ is coming</p>"
  end

  it 'does not allow for HTML injection from plaintext' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block '<p>this should render with entities</p>'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq "<p>&lt;p&gt;this should render with entities&lt;/p&gt;</p>"
  end

  it 'renders the various block types as their appropriate HTML elements' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      typed_block 'unstyled', 'plain text'
      typed_block 'paragraph', 'lorem ipsum'
      typed_block 'header-one', 'h1'
      typed_block 'header-two', 'h2'
      typed_block 'header-three', 'h3'
      typed_block 'header-four', 'h4'
      typed_block 'header-five', 'h5'
      typed_block 'header-six', 'h6'
      typed_block 'blockquote', 'minaswan'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <p>plain text</p>
      <p>lorem ipsum</p>
      <h1>h1</h1>
      <h2>h2</h2>
      <h3>h3</h3>
      <h4>h4</h4>
      <h5>h5</h5>
      <h6>h6</h6>
      <blockquote>minaswan</blockquote>
    HTML
  end

  it 'renders the "double-element" block types as their appropriate HTML elements' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      typed_block 'code-block', 'puts "hello"'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <pre><code>puts "hello"</code></pre>
    HTML
  end

  it 'renders the peer list-item block types as the same list' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      typed_block 'ordered-list-item', 'item 1'
      typed_block 'ordered-list-item', 'item 2'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <ol>
      <li>item 1</li>
      <li>item 2</li>
      </ol>
    HTML
  end

  it 'can have non-peer block-types after a peer block-type' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      typed_block 'ordered-list-item', 'item 1'
      text_block 'afterward'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <ol><li>item 1</li></ol>
      <p>afterward</p>
    HTML
  end

  it 'allows customizing the block type elements' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      typed_block 'arbitrary-block-type', 'opening section'
      text_block 'will still be rendered using defaults'
    end

    html = described_class.to_html(raw_draftjs, options: {
      block_type_mapping: {
        'arbitrary-block-type' => 'section',
      }
    })

    expect(html).to eq <<~HTML.strip
      <section>opening section</section><p>will still be rendered using defaults</p>
    HTML
  end

  it 'allows customizing the inline style elements' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'Winter is coming'
      inline_style 'BOLD', 7..8
    end

    html = described_class.to_html(raw_draftjs, options: {
      inline_style_mapping: {
        'BOLD' => 'strong',
      }
    })

    expect(html).to eq <<~HTML.strip
      <p>Winter <strong>is</strong> coming</p>
    HTML
  end

  it 'can apply inlineStyleRanges' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'afterward'
      inline_style 'BOLD', 5..8
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <p>after<b>ward</b></p>
    HTML
  end

  it 'generates valid HTML when inline styles overlap' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'afterward'
      inline_style 'BOLD', 5..8
      inline_style 'ITALIC', 0..5
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <p><i>after</i><b><i>w</i></b><b>ard</b></p>
    HTML
  end

  it 'renders the raw character text for an entity that has no defined style' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'afterward'
      apply_entity 'mention', 0..8, data: { url: 'https://example.com/users/1' }
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <p>afterward</p>
    HTML
  end

  it 'allows consumers to specify how entities are converted to HTML' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'afterward'
      apply_entity 'mention', 0..8, data: { url: 'https://example.com/users/1' }
    end

    html = described_class.to_html(raw_draftjs, options: {
      entity_style_mappings: {
        mention: ->(entity, content, *) {
          DraftjsHtml::Node.new('a', { href: entity.data['url'] }, content)
        },
      },
    })

    expect(html).to eq <<~HTML.strip
      <p><a href="https://example.com/users/1">afterward</a></p>
    HTML
  end

  it 'applies styles to entity-wrapped content' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'hey @sansa'
      apply_entity 'mention', 4..9, data: { url: 'https://example.com/users/1' }
      inline_style 'BOLD', 0..9
    end

    html = described_class.to_html(raw_draftjs, options: {
      entity_style_mappings: {
        mention: ->(entity, content, *) {
          content.wrap('a', { href: entity.data['url'] })
        },
      },
    })

    expect(html).to eq <<~HTML.strip
      <p><b>hey </b><b><a href="https://example.com/users/1">@sansa</a></b></p>
    HTML
  end

  it 'converts LINK entities to `a` tags' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block "Let's GO"
      apply_entity 'LINK', 6..7, data: {
        url: 'https://example.com/collect-200-dollars',
        rel: 'noreferrer',
        target: '_blank',
        title: 'Do not pass go',
        className: 'legend-of-zelda',
      }
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <p>Let's <a href="https://example.com/collect-200-dollars" rel="noreferrer" target="_blank" title="Do not pass go" class="legend-of-zelda">GO</a></p>
    HTML
  end

  it 'converts IMAGE entities to `img` tags' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'Look-y here'
      typed_block 'atomic', ' '
      apply_entity 'IMAGE', 0..1, data: {
        src: 'https://example.com/where',
        width: 400,
        height: 300,
        alt: 'An image',
        className: 'photography'
      }
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <p>Look-y here</p>
      <figure><img src="https://example.com/where" alt="An image" class="photography" width="400" height="300"></figure>
    HTML
  end

  it 'supports overriding the built-in style mappings with functions' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'afterward'
      inline_style 'BOLD', 5..8
      inline_style 'ITALIC', 5..8
    end

    html = described_class.to_html(raw_draftjs, options: {
      inline_style_renderer: ->(style_names, content, document) {
        Nokogiri::XML::Node.new("b", document).tap do |node|
          node.content = "#{content.to_s.upcase} #{style_names.join(',')}"
        end
      },
    })

    expect(html).to eq <<~HTML.strip
      <p>after<b>WARD BOLD,ITALIC</b></p>
    HTML
  end

  it 'protects against HTML injection with custom inline-style rendering' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'after<p>bold</p>'
      inline_style 'BOLD', 5..
    end

    html = described_class.to_html(raw_draftjs, options: {
      inline_style_renderer: ->(_style_names, content, _document) {
        "<b>#{content}</b>"
      },
    })

    expect(html).to eq <<~HTML.strip
      <p>after&lt;b&gt;&lt;p&gt;bold&lt;/p&gt;&lt;/b&gt;</p>
    HTML
  end

  it 'can fallback to default style rendering for basic styles and use the custom renderer for more complex ones' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'afterward'
      inline_style 'BOLD', 0..4
      inline_style 'CUSTOM', 5..8
    end

    html = described_class.to_html(raw_draftjs, options: {
      inline_style_renderer: ->(style_names, content, *) {
        next unless style_names == ['CUSTOM']
        content.wrap('strong')
      },
    })

    expect(html).to eq <<~HTML.strip
      <p><b>after</b><strong>ward</strong></p>
    HTML
  end

  it 'can style inline ranges and entities at the same time' do
    raw_draftjs = DraftjsHtml::Draftjs::RawDraftJs.build do
      text_block 'Come visit #Westeros!'
      inline_style 'BOLD', 11..22
      apply_entity 'LINK', 11..22, data: { url: 'https://westeros.example.com' }
    end

    html = described_class.to_html(raw_draftjs, options: {
      entity_style_mappings: {
        'LINK' => ->(entity, content, *) {
          content.wrap('a', { href: entity.data['url'] })
        },
      },
      inline_style_renderer: ->(_styles, content, *) {
        content.wrap('b')
      }
    })

    expect(html).to eq <<~HTML.strip
      <p>Come visit <b><a href="https://westeros.example.com">#Westeros!</a></b></p>
    HTML
  end
end
