# frozen_string_literal: true

RSpec.describe DraftjsHtml::FromHtml, 'From HTML - Security' do
  it 'does not render script tags' do
    raw_draftjs = subject.convert(<<~HTML)
      <script type="text/javascript">alert('you thought you were clever')</script>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {}
  end

  it 'handles invalid HTML gracefully (unclosed `p` tags)' do
    raw_draftjs = subject.convert(<<~HTML)
      <p>And then it falls off the cliff
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'And then it falls off the cliff'
    }
  end

  it 'handles invalid HTML gracefully (unclosed `b` tags)' do
    raw_draftjs = subject.convert(<<~HTML)
      <p>And then it falls <b>off the cliff
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'And then it falls off the cliff'
      inline_style 'BOLD', 18..30
    }
  end
end
