# frozen_string_literal: true

RSpec.describe DraftjsHtml do
  it "has a version number" do
    expect(DraftjsHtml::VERSION).not_to be nil
  end

  it 'generates valid HTML from the most basic of DraftJS' do
    html = described_class.to_html({ 'blocks' => [{ 'text' => 'Hello world!' }], 'entityMap' => {} })

    expect(html).to eq '<p>Hello world!</p>'
  end
end
