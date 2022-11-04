module DraftjsHtml::SpecSupport
  module KeyNormalization
    def normalize_keys(raw_draftjs)
      draftjs = DraftjsHtml::Draftjs::Content.parse(raw_draftjs)
      draftjs.blocks.each.with_index do |block, i|
        block.key = "block-key-#{i}"
      end

      draftjs.entity_map.keys.each.with_index do |entity_key, i|
        new_key = "entity-key-#{i}"
        draftjs.entity_map[new_key] = draftjs.entity_map.delete(entity_key)
        matching_entity_ranges = draftjs.blocks.flat_map { |block| block.raw_entity_ranges.select { |entity_range| entity_range['key'] == entity_key } }
        matching_entity_ranges.each { |range| range['key'] = new_key }
      end

      DraftjsHtml::Draftjs::ToRaw.new.convert(draftjs)
    end
  end
end

RSpec::Matchers.define :eq_raw_draftjs do |expected|
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

RSpec::Matchers.define :eq_raw_draftjs_ignoring_keys do |expected|
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
