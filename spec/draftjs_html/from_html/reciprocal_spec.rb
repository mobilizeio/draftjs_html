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

  it 'works on the case I actually care about' do
    html = '<p>Hi <a id="mob-widget-1"></a>, How are you?</p>'
    expect(DraftjsHtml.from_html(html)).to eq_raw_draftjs {
      text_block 'Hi  , How are you?'
      apply_entity 'LINK', 3..3, data: { id: 'mob-widget-1' }, mutability: 'MUTABLE'
    }
  end
end
