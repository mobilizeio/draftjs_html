module DraftjsHtml
  NokogiriNode = Struct.new(:node) do
    def to_nokogiri(_document)
      node
    end

    def wrap(tagname, attrs = {})
      Node.new(tagname, attrs, self)
    end

    def to_s
      node.to_s
    end
  end

  StringNode = Struct.new(:raw) do
    def to_nokogiri(document)
      lines = raw.lines
      text_nodes = lines.flat_map.with_index do |text, i|
        nodes = [Nokogiri::XML::Text.new(text.chomp, document)]
        nodes << Nokogiri::XML::Node.new('br', document) if text.end_with?("\n")
        nodes
      end

      Nokogiri::XML::NodeSet.new(document, text_nodes)
    end

    def wrap(tagname, attrs = {})
      Node.new(tagname, attrs, self)
    end

    def to_s
      raw.to_s
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
        node << content.to_nokogiri(document) if content
        (attributes || {}).each { |k, v| node[k] = v }
      end
    end

    def wrap(tagname, attrs = {})
      Node.new(tagname, attrs, self)
    end

    def to_s
      content.to_s
    end
  end
end
