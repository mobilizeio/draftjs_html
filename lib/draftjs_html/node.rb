module DraftjsHtml
  NokogiriNode = Struct.new(:node) do
    def to_nokogiri(_document)
      node
    end
  end

  StringNode = Struct.new(:raw) do
    def to_nokogiri(document)
      raw
      Nokogiri::XML::Text.new(raw, document)
    end
  end

  Node = Struct.new(:element_name, :attributes, :content) do
    def self.of(thing)
      case thing
      when Nokogiri::XML::Node then NokogiriNode.new(thing)
      when self.class then thing
      when String then StringNode.new(thing)
      else thing
      end
    end

    def to_nokogiri(document)
      Nokogiri::XML::Node.new(element_name, document).tap do |node|
        node.content = content
        (attributes || {}).each { |k, v| node[k] = v }
      end
    end
  end
end
