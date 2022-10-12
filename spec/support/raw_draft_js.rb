require 'securerandom'

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

  def block_type(type, text, depth: 0)
    @blocks << { 'key' => SecureRandom.urlsafe_base64(10), 'text' => text, 'type' => type, 'depth' => depth }
  end

  def inline_style(style_name, range)
    (@blocks.last['inlineStyleRanges'] ||= []) << { 'style' => style_name, 'offset' => range.begin, 'length' => range.size }
  end

  def entity_range(key, range)
    (@blocks.last['entityRanges'] ||= []) << { 'key' => key, 'offset' => range.begin, 'length' => range.size }
  end

  def apply_entity(type, range, data: {}, mutability: 'IMMUTABLE', key: SecureRandom.uuid)
    @entity_map[key] = {
      'type' => type,
      'mutability' => mutability,
      'data' => deep_stringify_keys(data),
    }

    entity_range(key, range)
  end

  def to_h
    {
      'blocks' => @blocks,
      'entityMap' => @entity_map,
    }
  end

  private

  def deep_stringify_keys(object)
    case object
    when Hash
      object.each_with_object({}) do |(key, value), result|
        result[key.to_s] = deep_stringify_keys(value)
      end
    when Array then object.map { |e| deep_stringify_keys(e) }
    else object
    end
  end
end
