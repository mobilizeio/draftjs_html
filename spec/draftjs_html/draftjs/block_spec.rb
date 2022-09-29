RSpec.describe DraftjsHtml::Draftjs::Block do
  it 'applies styles to each character in the text' do
    raw = RawDraftJs.build do
      text_block 'Winter is coming'
      inline_style 'BOLD', 0..5
      inline_style 'ITALIC', 7..8
      inline_style 'STRIKE', 10..15
    end
    block = described_class.parse(raw.dig('blocks', 0))

    expect(block.each_char.to_a.map(&:style_names)).to eq [
      ['BOLD'], ['BOLD'], ['BOLD'], ['BOLD'], ['BOLD'], ['BOLD'],
      [],
      ['ITALIC'], ['ITALIC'],
      [],
      ['STRIKE'], ['STRIKE'], ['STRIKE'], ['STRIKE'], ['STRIKE'], ['STRIKE'],
    ]
  end

  it 'applies multiple styles to the same character' do
    raw = RawDraftJs.build do
      text_block 'Winter is coming'
      inline_style 'ITALIC', 7..8
      inline_style 'BOLD', 7..8
    end
    block = described_class.parse(raw.dig('blocks', 0))

    expect(block.each_char.to_a.map(&:style_names)).to eq [
      [], [], [], [], [], [],
      [],
      ['ITALIC', 'BOLD'], ['ITALIC', 'BOLD'],
      [],
      [], [], [], [], [], [],
    ]
  end

  it 'applies overlapping styles' do
    raw = RawDraftJs.build do
      text_block 'Winter is coming'
      inline_style 'ITALIC', 7..8
      inline_style 'BOLD', 0..8
    end
    block = described_class.parse(raw.dig('blocks', 0))

    expect(block.each_char.to_a.map(&:style_names)).to eq [
      ['BOLD'], ['BOLD'], ['BOLD'], ['BOLD'], ['BOLD'], ['BOLD'],
      ['BOLD'],
      ['ITALIC', 'BOLD'], ['ITALIC', 'BOLD'],
      [],
      [], [], [], [], [], [],
    ]
  end

  it 'applies entities to ranges of characters, too' do
    raw = RawDraftJs.build do
      text_block 'Winter is coming'
      entity_range 'entity-key', 7..8
    end
    block = described_class.parse(raw.dig('blocks', 0))

    expect(block.each_char.to_a.map(&:entity_key)).to eq [
      nil, nil, nil, nil, nil, nil,
      nil,
      'entity-key', 'entity-key',
      nil,
      nil, nil, nil, nil, nil, nil,
    ]
  end

  it 'can return ranges of characters that all share the same styles' do
    raw = RawDraftJs.build do
      text_block 'Winter is coming'
      inline_style 'ITALIC', 7..8
      inline_style 'BOLD', 0..8
    end
    block = described_class.parse(raw.dig('blocks', 0))

    expect(block.each_range.to_a.map { {text: _1.text, style_names: _1.style_names} }).to eq [
      { text: 'Winter ', style_names: ['BOLD'] },
      { text: 'is', style_names: ['ITALIC', 'BOLD'] },
      { text: ' coming', style_names: [] },
    ]
  end
end
