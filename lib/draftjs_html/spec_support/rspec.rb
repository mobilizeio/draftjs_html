require 'rspec/expectations'
require 'draftjs_html/spec_support'

module DraftjsHtml
  module SpecSupport
    module RSpecMatchers
      extend RSpec::Matchers::DSL

      matcher :eq_raw_draftjs do |expected|
        include DraftjsHtml::SpecSupport::KeyNormalization
        match do |actual|
          @raw_draftjs = normalize_keys(DraftjsHtml::Draftjs::RawBuilder.build(&block_arg))
          @actual = normalize_keys(actual)

          values_match?(@raw_draftjs, @actual)
        end

        diffable

        def expected
          @raw_draftjs
        end
      end

      matcher :eq_raw_draftjs_ignoring_keys do |expected|
        include DraftjsHtml::SpecSupport::KeyNormalization
        match do |actual|
          @raw_draftjs = normalize_keys(expected)
          @actual = normalize_keys(actual)

          values_match?(@raw_draftjs, @actual)
        end

        diffable

        def expected
          @raw_draftjs
        end
      end
    end
  end
end
