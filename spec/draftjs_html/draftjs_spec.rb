# frozen_string_literal: true

RSpec.describe DraftjsHtml::Draftjs do
  it 'parses basic raw Draftjs' do
    draftjs = described_class.parse(RawDraftJs.build { })

    expect(draftjs.blocks.size).to eq 0
  end

  it 'can describe general block properties' do
    draftjs = described_class.parse(RawDraftJs.build do
      text_block 'hey there!'
    end)

    expect(draftjs.blocks.size).to eq 1

    block = draftjs.blocks.first
    expect(block.key).not_to be_nil
    expect(block.type).to eq 'unstyled'
    expect(block.length).to eq 10
    expect(block.plaintext).to eq 'hey there!'
  end
end
