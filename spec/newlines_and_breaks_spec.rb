# frozen_string_literal: true

RSpec.describe DraftjsHtml, 'DraftjsHtml - Newlines and <br> tags' do
  it 'generates <br/> tags for unstyled, empty blocks' do
    raw_draftjs = RawDraftJs.build do
      text_block 'Gimme a'
      text_block ''
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq "<p>Gimme a</p>\n<br>"
  end

  it 'generates <br/> tags for explicit newline characters between text' do
    raw_draftjs = RawDraftJs.build do
      text_block "Gimme a\nGimme a\n"
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq "<p>Gimme a<br>Gimme a</p>"
  end

  it 'keeps <br> tags at the beginning of a style range within a block' do
    raw_draftjs = RawDraftJs.build do
      text_block "There is only one thing we say to death:\n\nNot today."
      inline_style 'BOLD', 42..51
    end

    result = described_class.to_html(raw_draftjs, options: {
      squeeze_newlines: true,
    })

    expect(result).to eq '<p>There is only one thing we say to death:<br><b>Not today.</b></p>'
  end

  it 'chomps explicit newlines from the end of a block' do
    raw_draftjs = RawDraftJs.build do
      text_block "Valar Morghulis\n"
    end

    result = described_class.to_html(raw_draftjs, options: {
      squeeze_newlines: true,
    })

    expect(result).to eq '<p>Valar Morghulis</p>'
  end

  it 'allows squeezing/compacting/collapsing newlines' do
    raw_draftjs = RawDraftJs.build do
      text_block "Winter\n\nis coming"
    end

    html = described_class.to_html(raw_draftjs, options: {
      squeeze_newlines: true,
    })

    expect(html).to eq <<~HTML.strip
      <p>Winter<br>is coming</p>
    HTML
  end
end