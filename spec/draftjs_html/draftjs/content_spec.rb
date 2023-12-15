# frozen_string_literal: true

RSpec.describe DraftjsHtml::Draftjs::Content do
  describe '::parse' do
    let(:raw_input) { { 'blocks' => [], 'entityMap' => {} } }

    it 'can parse a valid raw draftjs' do
      expect(described_class.parse(raw_input)).to be_a(DraftjsHtml::Draftjs::Content)
    end

    it 'raises an InvalidRawDraftjs error when raw is nil' do
      expect { described_class.parse(nil) }.to raise_error(DraftjsHtml::InvalidRawDraftjs)
    end

    it 'raises an InvalidRawDraftjs error when raw["blocks"] is not an array' do
      expect { described_class.parse(raw_input.merge('blocks' => nil)) }.to raise_error(DraftjsHtml::InvalidRawDraftjs)
    end

    it 'raises an InvalidRawDraftjs error when raw["entityMap"] is not a hash' do
      expect { described_class.parse(raw_input.merge('entityMap' => nil)) }.to raise_error(DraftjsHtml::InvalidRawDraftjs)
    end
  end

  describe '#attach_entity' do
    it 'attaches an entity to a blocks range' do
      block = DraftjsHtml::Draftjs::Block.parse({ 'text' => 'any old text' })
      content = described_class.new(
        [block],
        DraftjsHtml::Draftjs::EntityMap.parse({})
      )
      entity = DraftjsHtml::Draftjs::Entity.parse({
        'type' => 'image',
        'mutability' => 'immutable',
        'data' => {
          'href' => 'https://example.com'
        }
      })

      content.attach_entity(entity, block, 0..2)

      expect(content.entity_map.size).to eq 1
      expect(block.entity_ranges.size).to eq 1
      expect(content.entity_map.keys.first).to eq block.entity_ranges.first.name
      expect(block.entity_ranges.first.range).to eq 0..2
    end
  end
end
