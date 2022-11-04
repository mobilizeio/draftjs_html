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
end
