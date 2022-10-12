# frozen_string_literal: true

RSpec.describe DraftjsHtml, 'DraftjsHtml - RTL Languages' do
  it 'adds the `dir` attribute to block elements when it can determine the content should be RTL' do
    raw_draftjs = RawDraftJs.build do
      text_block 'الشتاء قادم'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq '<p dir="rtl">الشتاء قادم</p>'
  end
end