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
end
