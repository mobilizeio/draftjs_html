# frozen_string_literal: true

RSpec.describe DraftjsHtml::FromHtml, 'Start->ToHtml->FromHtml == Start' do
  it 'converts style tags in such a way that they generate the same HTML' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block 'Hi, there!'
      inline_style 'BOLD', 4..8
    end

    expect(DraftjsHtml.from_html(DraftjsHtml.to_html(raw_draftjs))).to eq_raw_draftjs_ignoring_keys raw_draftjs
  end

  it 'converts entities in such a way that they generate the same HTML' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block 'Hi, a'
      apply_entity 'LINK', 4..4, data: { href: 'https://example.com/kittens' }, mutability: 'MUTABLE'
    end

    expect(DraftjsHtml.to_html(raw_draftjs)).to eq '<p>Hi, <a href="https://example.com/kittens">a</a></p>'
    expect(DraftjsHtml.from_html(DraftjsHtml.to_html(raw_draftjs))).to eq_raw_draftjs_ignoring_keys raw_draftjs
  end

  it 'can properly convert Microsoft Outlook nested ULs to HTML' do
    subject = described_class.new(squeeze_whitespace_blocks: true)
    raw_draftjs = subject.convert(<<~HTML)
      <div>
          <ul>
              <ul>
                  <li>item 1.1</li>
              </ul>
          </ul>
          <p>oh, hello</p>
          <ul>
              <ul>
                  <li>item 2.1</li>
              </ul>
          </ul>
      </div>
      <span>TTFN</span>
    HTML
    DraftjsHtml.to_html(raw_draftjs, options: {})

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unordered-list-item', 'item 1.1', depth: 1
      text_block 'oh, hello'
      typed_block 'unordered-list-item', 'item 2.1', depth: 1
      text_block 'TTFN'
    }
  end

  it 'can properly convert Microsoft Outlook nested block content in list items to HTML' do
    subject = described_class.new(squeeze_whitespace_blocks: true)
    raw_draftjs = subject.convert(<<~HTML)
      <div>
        <ul>
          <li>item 1
            <p>hello block content at depth 0</p>
            <ul>
                <li>item 1.1</li>
                <li>
                    <p>hello block content at depth 1</p>
                </li>
            </ul>
          </li>
          <li>item 2</li>
        </ul>
      </div>
      <span>TTFN</span>
    HTML
    DraftjsHtml.to_html(raw_draftjs, options: {})

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unordered-list-item', 'item 1hello block content at depth 0', depth: 0
      typed_block 'unordered-list-item', 'item 1.1', depth: 1
      typed_block 'unordered-list-item', 'hello block content at depth 1', depth: 1
      typed_block 'unordered-list-item', 'item 2', depth: 0
      text_block 'TTFN'
    }
  end
end
