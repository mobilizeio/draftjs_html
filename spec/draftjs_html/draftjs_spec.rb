# frozen_string_literal: true

RSpec.describe DraftjsHtml::Draftjs do
  it 'parses basic raw Draftjs' do
    draftjs = described_class.parse(DraftjsHtml::Draftjs::RawBuilder.build { })

    expect(draftjs.blocks.size).to eq 0
  end

  it 'can describe general block properties' do
    draftjs = described_class.parse(DraftjsHtml::Draftjs::RawBuilder.build do
      text_block 'hey there!'
    end)

    expect(draftjs.blocks.size).to eq 1

    block = draftjs.blocks.first
    expect(block.key).not_to be_nil
    expect(block.type).to eq 'unstyled'
    expect(block.length).to eq 10
    expect(block.plaintext).to eq 'hey there!'
  end

  it 'parses and stores entities from the entityMap' do
    draftjs = described_class.parse(DraftjsHtml::Draftjs::RawBuilder.build do
      text_block '@sansa'
      apply_entity 'mention', 0..5, key: 'mention-1', mutability: 'MUTABLE', data: {
        url: 'https://example.com/users/sansa'
      }
    end)

    expect(draftjs.entity_map.size).to eq 1

    entity = draftjs.find_entity 'mention-1'
    expect(entity.mutability).to eq 'MUTABLE'
    expect(entity.data).to eq('url' => 'https://example.com/users/sansa')
  end

  it 'can convert back to a valid raw format' do
    draftjs = described_class.parse(DraftjsHtml::Draftjs::RawBuilder.build do
      text_block '@sansa'
      inline_style 'BOLD', 0..5
      apply_entity 'mention', 0..5, key: 'mention-1', mutability: 'MUTABLE', data: {
        url: 'https://example.com/users/sansa'
      }

      text_block 'another block'
    end)

    expect(draftjs.to_raw).to match({
      'blocks' => [
        {
          'text' => '@sansa',
          'inlineStyleRanges' => [{ 'style' => 'BOLD', 'offset' => 0, 'length' => 6 }],
          'entityRanges' => [{ 'key' => 'mention-1', 'offset' => 0, 'length' => 6 }],
          'type' => 'unstyled',
          'depth' => 0,
        },
        {
          'text' => 'another block',
          'inlineStyleRanges' => [],
          'entityRanges' => [],
          'type' => 'unstyled',
          'depth' => 0,
        },
      ],
      'entityMap' => {
        'mention-1' => {
          'type' => 'mention',
          'mutability' => 'MUTABLE',
          'data' => { 'url' => 'https://example.com/users/sansa' },
        }
      }
    })
  end
end
