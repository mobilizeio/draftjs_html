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

  def block_type(type, text)
    @blocks << { 'key' => SecureRandom.urlsafe_base64(10), 'text' => text, 'type' => type }
  end

  def inline_style(style_name, range)
    (@blocks.last['inlineStyleRanges'] ||= []) << { 'style' => style_name, 'offset' => range.begin, 'length' => range.size }
  end

  def entity_range(key, range)
    (@blocks.last['entityRanges'] ||= []) << { 'key' => key, 'offset' => range.begin, 'length' => range.size }
  end

  def to_h
    {
      'blocks' => @blocks,
      'entityMap' => @entity_map,
    }
  end
end
