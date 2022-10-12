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
end
