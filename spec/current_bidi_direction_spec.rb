# frozen_string_literal: true

RSpec.describe DraftjsHtml::CurrentBidiDirection do
  let(:empty) { '' }
  let(:french) { "Fran\u00E7ais" }
  let(:hebrew) { "\u05D0\u05DC\u05E4\u05D1\u05D9\u05EA" }
  let(:arabic) { "\u0639\u0631\u0628\u064A" }
  let(:korean) { "\uD55C\uAD6D\uC5B4" }

  describe 'reset' do
    it 'should reset to default direction (LTR)' do
      subject = described_class.new(DraftjsHtml::CurrentBidiDirection::LTR)
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::LTR
      expect(subject.update(hebrew)).to eq DraftjsHtml::CurrentBidiDirection::RTL
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::RTL

      subject.reset
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::LTR

      subject.reset
      expect(subject.update(arabic)).to eq DraftjsHtml::CurrentBidiDirection::RTL

      subject.reset
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::LTR
    end

    it 'should reset to default direction (RTL)' do
      subject = described_class.new(DraftjsHtml::CurrentBidiDirection::RTL)
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::RTL
      expect(subject.update(french)).to eq DraftjsHtml::CurrentBidiDirection::LTR
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::LTR

      subject.reset
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::RTL

      subject.reset
      expect(subject.update(korean)).to eq DraftjsHtml::CurrentBidiDirection::LTR

      subject.reset
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::RTL
    end
  end

  describe 'get_direction' do
    it 'should remember the last direction' do
      subject = described_class.new

      expect(subject.update('ascii')).to eq DraftjsHtml::CurrentBidiDirection::LTR
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::LTR
      expect(subject.update('([{}])')).to eq DraftjsHtml::CurrentBidiDirection::LTR
      expect(subject.update('1234567890')).to eq DraftjsHtml::CurrentBidiDirection::LTR

      expect(subject.update(hebrew)).to eq DraftjsHtml::CurrentBidiDirection::RTL
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::RTL
      expect(subject.update('([{}])')).to eq DraftjsHtml::CurrentBidiDirection::RTL
      expect(subject.update('1234567890')).to eq DraftjsHtml::CurrentBidiDirection::RTL

      expect(subject.update(french)).to eq DraftjsHtml::CurrentBidiDirection::LTR
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::LTR

      expect(subject.update(arabic)).to eq DraftjsHtml::CurrentBidiDirection::RTL
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::RTL

      expect(subject.update(korean)).to eq DraftjsHtml::CurrentBidiDirection::LTR
      expect(subject.update(empty)).to eq DraftjsHtml::CurrentBidiDirection::LTR
    end
  end
end
