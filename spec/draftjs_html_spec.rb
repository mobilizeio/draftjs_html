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
      @blocks << { 'text' => text }
    end

    def to_h
      {
        'blocks' => @blocks,
        'entityMap' => @entity_map,
      }
    end
  end
end
