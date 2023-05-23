module DraftjsHtml
  # This class manages the depth and nesting of the myriad HTML tags generated by DraftjsHtml::ToHtml.
  # It is intended to be a private implementation detail.
  class HtmlDepth # :nodoc:
    BLOCK_TYPE_TO_HTML_WRAPPER = {
      'code-block' => 'pre',
      'ordered-list-item' => 'ol',
      'unordered-list-item' => 'ul',
    }.freeze

    def initialize(body)
      @current_depth = 0
      @body = body
      @previous_parents = [body.parent]
      @nesting_roots = [body.parent.name]
    end

    def apply(block)
      return unless nesting_root_changed?(block) || depth_changed?(block)

      if deepening?(block)
        deepen(block, desired_depth_change: block.depth - @current_depth)
      elsif rising?(block) && still_nested?(block)
        rise(times: @current_depth - block.depth)
      elsif rising?(block)
        rise(times: @current_depth - block.depth)
        pop_parent
      elsif still_nested?(block)
        push_parent(block)
      elsif nested?
        pop_parent
      end

      @current_depth = block.depth
    end

    private

    def deepen(block, desired_depth_change: 0)
      if inside_valid_nesting_root?
        set_previous_li_as_parent(block)
      else
        create_valid_nesting_root(block)
      end

      (desired_depth_change - 1).times do
        create_valid_nesting_root(block)
      end

      push_parent(block)
    end

    def push_parent(block)
      tagname = BLOCK_TYPE_TO_HTML_WRAPPER[block.type]
      node = create_child(tagname)
      @previous_parents << @body.parent
      @body.parent = node
    end

    def rise(times:)
      times.times do
        begin
          pop_parent
        end while @body.parent.name != @nesting_roots.last
        @nesting_roots.pop
      end
    end

    def pop_parent
      @body.parent = @previous_parents.pop unless @previous_parents.empty?
    end

    def create_child(tagname)
      @body.parent.add_child(@body.doc.create_element(tagname))
    end

    def nested?
      @body.parent.name != 'body'
    end

    def still_nested?(block)
      BLOCK_TYPE_TO_HTML_WRAPPER[block.type]
    end

    def depth_changed?(block)
      block.depth != @current_depth
    end

    def nesting_root_changed?(block)
      @body.parent.name != BLOCK_TYPE_TO_HTML_WRAPPER[block.type]
    end

    def rising?(block)
      @current_depth > block.depth
    end

    def deepening?(block)
      @current_depth < block.depth
    end

    def create_valid_nesting_root(block)
      parent_tagname = BLOCK_TYPE_TO_HTML_WRAPPER[block.type]
      node = create_child(parent_tagname)
      @previous_parents << node
      @nesting_roots << parent_tagname
      @body.parent = node

      list_item = create_child('li')
      @body.parent = list_item
    end

    def set_previous_li_as_parent(block)
      tagname = BLOCK_TYPE_TO_HTML_WRAPPER[block.type]
      @previous_parents << @body.parent
      @nesting_roots << tagname
      @body.parent = @body.parent.last_element_child
    end

    def inside_valid_nesting_root?
      BLOCK_TYPE_TO_HTML_WRAPPER.values.include?(@body.parent.name)
    end
  end
end
