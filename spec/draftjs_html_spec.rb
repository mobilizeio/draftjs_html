# frozen_string_literal: true

RSpec.describe DraftjsHtml do
  it "has a version number" do
    expect(DraftjsHtml::VERSION).not_to be nil
  end

  it 'generates valid HTML from the most basic of DraftJS' do
    raw_draftjs = RawDraftJs.build do
      text_block 'Hello world!'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq '<p>Hello world!</p>'
  end

  it 'supports generating multiple blocks of plain text' do
    raw_draftjs = RawDraftJs.build do
      text_block 'Hello world!'
      text_block 'Winter is coming.'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq "<p>Hello world!</p>\n<p>Winter is coming.</p>"
  end

  it 'renders the various block types as their appropriate HTML elements' do
    raw_draftjs = RawDraftJs.build do
      block_type 'unstyled', 'plain text'
      block_type 'paragraph', 'lorem ipsum'
      block_type 'header-one', 'h1'
      block_type 'header-two', 'h2'
      block_type 'header-three', 'h3'
      block_type 'header-four', 'h4'
      block_type 'header-five', 'h5'
      block_type 'header-six', 'h6'
      block_type 'blockquote', 'minaswan'
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
    raw_draftjs = RawDraftJs.build do
      block_type 'code-block', 'puts "hello"'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <pre><code>puts "hello"</code></pre>
    HTML
  end

  it 'renders the peer list-item block types as the same list' do
    raw_draftjs = RawDraftJs.build do
      block_type 'ordered-list-item', 'item 1'
      block_type 'ordered-list-item', 'item 2'
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
    raw_draftjs = RawDraftJs.build do
      block_type 'ordered-list-item', 'item 1'
      text_block 'afterward'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <ol><li>item 1</li></ol>
      <p>afterward</p>
    HTML
  end

  it 'can apply inlineStyleRanges' do
    raw_draftjs = RawDraftJs.build do
      text_block 'afterward'
      inline_style 'BOLD', 5..8
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <p>after<b>ward</b></p>
    HTML
  end

  it 'generates valid HTML when inline styles overlap' do
    raw_draftjs = RawDraftJs.build do
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
    raw_draftjs = RawDraftJs.build do
      text_block 'afterward'
      apply_entity 'mention', 0..8, data: { url: 'https://example.com/users/1' }
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <p>afterward</p>
    HTML
  end

  it 'allows consumers to specify how entities are converted to HTML' do
    raw_draftjs = RawDraftJs.build do
      text_block 'afterward'
      apply_entity 'mention', 0..8, data: { url: 'https://example.com/users/1' }
    end

    html = described_class.to_html(raw_draftjs, options: {
      style_entity: ->(entity, content) {
        "<a href=#{entity.data['url']}>#{content}</a>"
      }
    })

    expect(html).to eq <<~HTML.strip
      <p><a href="https://example.com/users/1">afterward</a></p>
    HTML
  end

  it 'applies styles to entity-wrapped content' do
    raw_draftjs = RawDraftJs.build do
      text_block 'hey @sansa'
      apply_entity 'mention', 4..9, data: { url: 'https://example.com/users/1' }
      inline_style 'BOLD', 0..9
    end

    html = described_class.to_html(raw_draftjs, options: {
      style_entity: ->(entity, content) {
        "<a href=#{entity.data['url']}>#{content}</a>"
      }
    })

    expect(html).to eq <<~HTML.strip
      <p><b>hey </b><b><a href="https://example.com/users/1">@sansa</a></b></p>
    HTML
  end
end
