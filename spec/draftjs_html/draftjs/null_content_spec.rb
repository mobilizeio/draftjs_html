# frozen_string_literal: true

RSpec.describe DraftjsHtml::Draftjs::NullContent do
  it 'keeps message parity with DraftjsHtml::Draftjs::Content' do
    include_super_methods = false
    expect(
      described_class.instance_methods(include_super_methods)
    ).to match_array([
      *DraftjsHtml::Draftjs::Content.instance_methods(include_super_methods),
    ])
  end

  describe '#blocks' do
    it 'returns a sane value' do
      expect(subject.blocks).to eq([])
    end
  end

  describe '#entity_map' do
    it 'returns a sane value' do
      expect(subject.entity_map).to eq({})
    end
  end

  describe '#find_entity' do
    it 'is a no-op' do
      expect(subject.find_entity('key')).to be_nil
    end
  end

  describe '#attach_entity' do
    it 'is a no-op' do
      expect(subject.attach_entity('entity', 'block', 'range')).to be_nil
    end
  end

  describe '#to_raw' do
    it 'returns a sane value' do
      expect(subject.to_raw).to eq({ 'blocks' => [], 'entityMap' => {} })
    end
  end

  describe '#valid?' do
    it 'returns false always' do
      expect(subject).to_not be_valid
    end
  end

  describe '#invalid?' do
    it 'returns true always' do
      expect(subject).to be_invalid
    end
  end
end
