# frozen_string_literal: true

RSpec.describe DraftjsHtml::FromHtml::CharList do
  let(:char) { DraftjsHtml::FromHtml::CharList::Char }
  let(:entity) { DraftjsHtml::Draftjs::Entity.new(type: 'LINK', data: { href: 'https://example.com' }) }

  it 'can append a whole string to its list' do
    subject.append('hi there!')

    expect(subject.chars.map(&:it)).to eq [
      'h', 'i',
      ' ',
      't', 'h', 'e', 'r', 'e',
      '!',
    ]
  end

  it 'can retrieve the plaintext' do
    subject.append('hi there!')

    expect(subject.text).to eq 'hi there!'
    expect(subject.size).to eq 9
  end

  it 'attaches passed entities to each char in the string' do
    entity = DraftjsHtml::Draftjs::Entity.new(type: 'LINK', data: { href: 'https://example.com' })
    subject.append('hi there!', entity: entity)

    expect(subject.entity_ranges).to eq([described_class::EntityRange.new(entity: entity, start: 0, finish: 8)])
    expect(subject.text).to eq 'hi there!'
  end

  it 'can attach entities in the middle of a charlist' do
    subject.append('oh ')
    subject.append('hello', entity: entity)
    subject.append(' there!')

    expect(subject.entity_ranges.map(&:range)).to eq([3..7])
    expect(subject.text).to eq 'oh hello there!'
  end

  it 'can attach entities to text later' do
    subject.append('hi there!')
    subject.apply_entity(0..1, entity)

    expect(subject.entity_ranges.map(&:range)).to eq([0..1])
  end

  it 'attaches passed styles to each char in the string' do
    subject.append('hi there!', styles: %w[BOLD ITALIC])

    expect(subject.style_ranges).to eq([
      described_class::StyleRange.new(style: 'BOLD', start: 0, finish: 8),
      described_class::StyleRange.new(style: 'ITALIC', start: 0, finish: 8),
    ])
    expect(subject.text).to eq 'hi there!'
  end

  it 'can append styles to text later' do
    subject.append('hi there!')
    subject.append_styles(0..1, %w[UNDERSCORE])

    expect(subject.style_ranges).to eq([
      described_class::StyleRange.new(style: 'UNDERSCORE', start: 0, finish: 1),
    ])
    expect(subject.text).to eq 'hi there!'
  end

  it 'generates correct ranges for overlapping styles' do
    subject.append('hi there!')
    subject.append_styles(0..5, %w[UNDERSCORE])
    subject.append_styles(4..8, %w[BOLD])

    expect(subject.style_ranges).to eq([
      described_class::StyleRange.new(style: 'UNDERSCORE', start: 0, finish: 5),
      described_class::StyleRange.new(style: 'BOLD', start: 4, finish: 8),
    ])
    expect(subject.text).to eq 'hi there!'
  end

  it 'can add another charlist to its data and updates entity range indexes' do
    list1 = described_class.new
    list1.append('hi ')
    list1.apply_entity(0..1, entity.dup)
    list2 = described_class.new
    list2.append('there!')
    list2.apply_entity(0..1, entity.dup)

    subject = list1 + list2

    expect(subject.text).to eq 'hi there!'
    expect(subject.entity_ranges.map(&:range)).to eq([0..1, 3..4])
  end

  it 'can enumerate lines of chars as charlists' do
    subject.append("line1\nline2\nline3")

    expect(subject.each_line.to_a.map(&:text)).to eq %w[line1 line2 line3]
  end

  it 'retains entity attachments when enumerating lines' do
    subject.append("line1\nline2\nline3")
    subject.apply_entity(6..10, entity)

    expect(subject.each_line.to_a.map { _1.entity_ranges.map(&:range) }).to eq [
      [],
      [0..4],
      [],
    ]
  end

  it 'adds a whitespace character for atomic entities' do
    subject.append_atomic_entity(entity)

    expect(subject.text).to eq ' '
  end

  it 'creates a line between pre-existing content when adding an atomic entity' do
    subject.append('pre-entity')
    subject.append_atomic_entity(entity)

    expect(subject.text).to eq "pre-entity\n "
  end

  it 'adds a line between pre-existing atomic entities and new content' do
    subject.append('pre-entity')
    subject.append_atomic_entity(entity)
    subject.append('post-entity')

    expect(subject.text).to eq "pre-entity\n \npost-entity"
  end
end
