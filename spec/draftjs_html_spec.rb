# frozen_string_literal: true

RSpec.describe DraftjsHtml do
  it "has a version number" do
    expect(DraftjsHtml::VERSION).not_to be nil
  end

  it 'generates valid HTML from the most basic of DraftJS' do
    raw_draftjs = RawDraftJs.build do
      text_block 'Hello world!'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq '<p>Hello world!</p>'
  end

  it 'supports generating multiple blocks of plain text' do
    raw_draftjs = RawDraftJs.build do
      text_block 'Hello world!'
      text_block 'Winter is coming.'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq "<p>Hello world!</p>\n<p>Winter is coming.</p>"
  end

  it 'renders the various block types as their appropriate HTML elements' do
    raw_draftjs = RawDraftJs.build do
      block_type 'unstyled', 'plain text'
      block_type 'paragraph', 'lorem ipsum'
      block_type 'header-one', 'h1'
      block_type 'header-two', 'h2'
      block_type 'header-three', 'h3'
      block_type 'header-four', 'h4'
      block_type 'header-five', 'h5'
      block_type 'header-six', 'h6'
      block_type 'blockquote', 'minaswan'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq <<~HTML.strip
      <p>plain text</p>
      <p>lorem ipsum</p>
      <h1>h1</h1>
      <h2>h2</h2>
      <h3>h3</h3>
      <h4>h4</h4>
      <h5>h5</h5>
      <h6>h6</h6>
      <blockquote>minaswan</blockquote>
    HTML
  end

  private

  class RawDraftJs
    def self.build(&block)
      instance = new
      instance.instance_eval(&block)
      instance.to_h
    end

    def initialize
      @blocks = []
      @entity_map = {}
    end

    def text_block(text)
      block_type('unstyled', text)
    end

    def block_type(type, text)
      @blocks << { 'text' => text, 'type' => type }
    end

    def to_h
      {
        'blocks' => @blocks,
        'entityMap' => @entity_map,
      }
    end
  end
end
