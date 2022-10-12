# frozen_string_literal: true

RSpec.describe DraftjsHtml, 'DraftjsHtml - Block Depth & Nesting' do
  it 'renders nested peer list-item block types as the same list' do
    raw_draftjs = RawDraftJs.build do
      block_type 'ordered-list-item', 'item 1'
      block_type 'ordered-list-item', 'item 1.1', depth: 1
      block_type 'ordered-list-item', 'item 1.1.1', depth: 2
      block_type 'ordered-list-item', 'item 1.2', depth: 1
      block_type 'ordered-list-item', 'item 2', depth: 0
      text_block 'And something after'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq_ignoring_whitespace <<~HTML.strip
      <ol>
      <li>item 1
        <ol>
          <li>item 1.1
          <ol><li>item 1.1.1</li></ol>
          </li>
          <li>item 1.2</li>
        </ol>
      </li>
      <li>item 2</li>
      </ol>
      <p>And something after</p>
    HTML
  end

  it 'pops depth all the way up' do
    raw_draftjs = RawDraftJs.build do
      block_type 'ordered-list-item', 'item 1'
      block_type 'ordered-list-item', 'item 1.1', depth: 1
      block_type 'ordered-list-item', 'item 1.1.1', depth: 2
      text_block 'And something after'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq_ignoring_whitespace <<~HTML.strip
      <ol>
      <li>item 1
        <ol>
          <li>item 1.1
          <ol><li>item 1.1.1</li></ol>
          </li>
        </ol>
      </li>
      </ol>
      <p>And something after</p>
    HTML
  end

  it 'handles depth on non-nested peer block types' do
    raw_draftjs = RawDraftJs.build do
      text_block 'Top level'
      block_type 'ordered-list-item', 'Item 1', depth: 0
      block_type 'ordered-list-item', 'Item 1.1', depth: 1
      block_type 'unstyled', 'Has depth, but just a tag', depth: 1
      block_type 'unstyled', '', depth: 0
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq_ignoring_whitespace <<~HTML.strip
      <p>Top level</p>
      <ol>
        <li>Item 1
          <ol><li>Item 1.1</li></ol>
          <p>Has depth, but just a tag</p>
        </li>
      </ol>
      <br>
    HTML
  end

  it 'properly places non-list items within the current nesting' do
    raw_draftjs = RawDraftJs.build do
      block_type 'unordered-list-item', 'item 1', depth: 0
      block_type 'unordered-list-item', 'item 1.1', depth: 1
      block_type 'unstyled', '', depth: 1
      block_type 'unordered-list-item', 'item 2', depth: 0
      block_type 'unordered-list-item', 'item 2.1', depth: 1
      block_type 'unordered-list-item', 'item 2.2', depth: 1
      block_type 'unstyled', '', depth: 1
      block_type 'unstyled', ' ', depth: 0
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq_ignoring_whitespace <<~HTML.strip
      <ul>
        <li>item 1
          <ul>
            <li>item 1.1</li>
          </ul>
          <br>
        </li>
        <li>item 2
          <ul>
            <li>item 2.1</li>
            <li>item 2.2</li>
          </ul>
          <br>
        </li>
      </ul>
      <p></p>
    HTML
  end
end
