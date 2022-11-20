# frozen_string_literal: true

RSpec.describe DraftjsHtml, 'DraftjsHtml - RTL Languages' do
  it 'adds the `dir` attribute to block elements when it can determine the content should be RTL' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block 'الشتاء قادم'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq '<p dir="rtl">الشتاء قادم</p>'
  end

  it 'adds the `dir` attribute on all parent elements up to the highest block-parent' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block 'الشتاء قادم'
      inline_style 'UNDERLINE', 0..10
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq '<p dir="rtl"><u dir="rtl">الشتاء قادم</u></p>'
  end

  it 'applies `dir` to all parents on lists' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      typed_block 'ordered-list-item', 'الشتاء قادم', depth: 0
      typed_block 'ordered-list-item', 'Winter is coming', depth: 1
      typed_block 'ordered-list-item', 'الشتاء قادم', depth: 1
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq_ignoring_whitespace <<~HTML
      <ol dir="rtl">
        <li dir="rtl">الشتاء قادم
          <ol dir="rtl">
            <li>Winter is coming</li>
            <li dir="rtl">الشتاء قادم</li>
          </ol>
        </li>
      </ol>
    HTML
  end

  it 'creates block-level (div) tags with `dir="rtl"` for an RTL inline style' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block 'Winter is coming'
      inline_style 'RTL', 0..15
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq_ignoring_whitespace <<~HTML
      <p><div dir="rtl">Winter is coming</div></p>
    HTML
  end
end
