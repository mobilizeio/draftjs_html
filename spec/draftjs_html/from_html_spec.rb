# frozen_string_literal: true

RSpec.describe DraftjsHtml::FromHtml do
  it 'converts a line of plaintext into a single DraftJS block' do
    raw_draftjs = subject.convert('a line of raw text')

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'a line of raw text'
    }
  end

  it 'converts multiple lines of plaintext into individual DraftJS blocks' do
    raw_draftjs = subject.convert("a first line\na second line")

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'a first line'
      text_block 'a second line'
    }
  end

  it 'ignores trailing newlines' do
    raw_draftjs = subject.convert("a first line\n")

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'a first line'
    }
  end

  it 'converts sequential `p` tags to lines' do
    raw_draftjs = subject.convert("<p>a first line</p><p>a second line</p>")

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'a first line'
      text_block 'a second line'
    }
  end

  it 'treats `br` tags as a block-break' do
    raw_draftjs = subject.convert("<p>a first line<br>a second line</p>")

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'a first line'
      text_block 'a second line'
    }
  end

  it 'can end in `br` tags' do
    raw_draftjs = subject.convert(<<~HTML)
      <ul><li>Share progress</li></ul>
      <p>Do the stuff</p><br>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unordered-list-item', 'Share progress'
      text_block 'Do the stuff'
      text_block ''
    }
  end

  it 'creates `header-one` blocks for `h1` tags' do
    raw_draftjs = subject.convert("<h1>Header line</h1><p>A paragraph</p>")

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'header-one', 'Header line'
      text_block 'A paragraph'
    }
  end

  it 'creates `ordered-list-item` blocks for `ol > li` tags' do
    raw_draftjs = subject.convert(<<~HTML)
      <ol>
        <li>Item 1</li>
        <li>Item 2</li>
      </ol>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'ordered-list-item', 'Item 1'
      typed_block 'ordered-list-item', 'Item 2'
    }
  end

  it 'handles deeply nested `ul > li` tags' do
    raw_draftjs = subject.convert(<<~HTML)
      <ul>
        <li>Item 1
          <ol>
            <li>Item 1.1</li>
          </ol>
        </li>
        <li>Item 2</li>
      </ul>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unordered-list-item', 'Item 1'
      typed_block 'ordered-list-item', 'Item 1.1', depth: 1
      typed_block 'unordered-list-item', 'Item 2'
    }
  end

  it 'converts `<b>` tags into a `BOLD` `inlineStyleRange`' do
    raw_draftjs = subject.convert(<<~HTML)
      <p>Winter <b>is</b> coming</p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Winter is coming'
      inline_style 'BOLD', 7..8
    }
  end

  it 'handles nested `inlineStyleRange` tags' do
    raw_draftjs = subject.convert(<<~HTML)
      <p><b>Winter <i>is</i> coming</b></p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Winter is coming'
      inline_style 'BOLD', 0..15
      inline_style 'ITALIC', 7..8
    }
  end

  it 'accurately tracks depth for nested "flow" elements inside list items' do
    raw_draftjs = subject.convert(<<~HTML)
      <ul>
        <li><p>Item 1</p>
          <ol>
            <li><p>Item 1.1</p></li>
          </ol>
        </li>
        <li><p>Item 2</p></li>
      </ul>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unordered-list-item', 'Item 1'
      typed_block 'ordered-list-item', 'Item 1.1', depth: 1
      typed_block 'unordered-list-item', 'Item 2'
    }
  end

  it 'creates `IMAGE` `entities` from `img` tags' do
    raw_draftjs = subject.convert(<<~HTML)
      <img src="https://example.com/placekitten" alt="A kitten!" class="my-image" height="100" width="300"/>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'atomic', ' '
      apply_entity 'IMAGE', 0..0, data: {
        src: 'https://example.com/placekitten',
        alt: 'A kitten!',
        class: 'my-image',
        height: '100',
        width: '300',
      }
    }
  end

  it 'can create image tags in the middle of other content' do
    raw_draftjs = subject.convert(<<~HTML)
      <ul><li>Hi! <ul><li><img src="https://example.com/placekitten"/></li></ul></li></ul>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unordered-list-item', 'Hi! ', depth: 0
      typed_block 'atomic', ' ', depth: 1
      apply_entity 'IMAGE', 0..0, data: { src: 'https://example.com/placekitten' }
    }
  end

  it 'creates IMAGE entities outside top-level block elements (p tags) - technically invalid HTML' do
    raw_draftjs = subject.convert(<<~HTML)
      <p>Oh ... hello <img src="https://example.com/placekitten"/></p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Oh ... hello '
      typed_block 'atomic', ' '
      apply_entity 'IMAGE', 0..0, data: { src: 'https://example.com/placekitten' }
    }
  end

  it 'creates LINK entities wrapping their content' do
    raw_draftjs = subject.convert(<<~HTML)
      <p>Oh ... <a href="https://example.com/visit">hello</a></p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Oh ... hello'
      apply_entity 'LINK', 7..11, data: { href: 'https://example.com/visit' }, mutability: 'MUTABLE'
    }
  end

  it 'gracefully consumes content inside non-semantic elements' do
    raw_draftjs = subject.convert(<<~HTML)
      <div>Oh ... <a href="https://example.com/visit">hello</a></divp>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Oh ... hello'
      apply_entity 'LINK', 7..11, data: { href: 'https://example.com/visit' }, mutability: 'MUTABLE'
    }
  end

  it 'does not create new blocks for inline content tags (spans)' do
    raw_draftjs = subject.convert(<<~HTML)
      <p>Lookie here! A <span id="hashtag-123">#hashtag</span></p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Lookie here! A #hashtag'
    }
  end

  it 'allows configuring entity processing per HTML node' do
    options = {
      node_to_entity: ->(tagname, content, attributes) {
        id = attributes['id'].to_s
        if tagname == 'span' && id.start_with?('hashtag-')
          { type: 'HASHTAG', data: { name: content[1..], id: id.gsub('hashtag-', '').to_i } }
        end
      }
    }
    subject = described_class.new(options)
    raw_draftjs = subject.convert(<<~HTML)
      <p>Lookie here! A <span id="hashtag-123">#hashtag</span></p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Lookie here! A #hashtag'
      apply_entity 'HASHTAG', 15..22, data: { name: 'hashtag', id: 123 }
    }
  end

  it 'can create custom entities for arbitrary nodes' do
    options = {
      node_to_entity: ->(tagname, _content, attributes) {
        if tagname == 'p'
          { type: 'ARBITRARY', data: attributes }
        end
      }
    }
    subject = described_class.new(options)
    raw_draftjs = subject.convert(<<~HTML)
      <p data-attr="1">This whole thing is an entity</p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'This whole thing is an entity'
      apply_entity 'ARBITRARY', 0..28, data: { 'data-attr' => '1' }
    }
  end

  it 'can create custom entities for arbitrary, empty nodes (must add a character to attach to)' do
    options = {
      node_to_entity: ->(tagname, _content, attributes) {
        if tagname == 'span'
          { type: 'ARBITRARY', data: attributes }
        end
      }
    }
    subject = described_class.new(options)
    raw_draftjs = subject.convert(<<~HTML)
      <p><span data-attr="1"></span></p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unstyled', ' '
      apply_entity 'ARBITRARY', 0..0, data: { 'data-attr' => '1' }
    }
  end

  it 'can create custom entities for arbitrary, empty nodes inside block nodes' do
    options = {
      node_to_entity: ->(tagname, _content, attributes) {
        if tagname == 'span'
          { type: 'ARBITRARY', data: attributes }
        end
      }
    }
    subject = described_class.new(options)
    raw_draftjs = subject.convert(<<~HTML)
      <p>Hi <span data-attr="1"></span>,</p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Hi  ,'
      apply_entity 'ARBITRARY', 3..3, data: { 'data-attr' => '1' }
    }
  end

  it 'can override the entity processing for LINK entities' do
    options = {
      node_to_entity: ->(tagname, _content, _attributes) {
        if tagname == 'a'
          { type: 'CUSTOM-LINK', data: { custom: 1 } }
        end
      }
    }
    subject = described_class.new(options)
    raw_draftjs = subject.convert(<<~HTML)
      <p>Prepare to be <a href="#ignored">overridden</a></p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Prepare to be overridden'
      apply_entity 'CUSTOM-LINK', 14..23, data: { custom: 1 }
    }
  end

  it 'renders the correct block type for each of the known HTML elements' do
    unstyled_tags = %w[
      address article aside dd div dl dt fieldset figcaption
      footer form header hr main nav section tfoot video
    ]

    unstyled_tags.each do |tag|
      subject = described_class.new
      expect(subject.convert("<#{tag}>text</#{tag}>")).to eq_raw_draftjs { text_block 'text' }, "failed for #{tag}"
    end

    block_elements_that_dont_need_parents = DraftjsHtml::HtmlDefaults::BLOCK_TYPE_TO_HTML.invert.reject do |tag, _|
      %w[li code].include?(tag)
    end

    block_elements_that_dont_need_parents.each do |tag, block_type|
      subject = described_class.new
      expect(subject.convert("<#{tag}>text</#{tag}>")).to eq_raw_draftjs { typed_block block_type, 'text' }
    end
  end

  it '"ignores" invalid block elements inside inline elements' do
    raw_draftjs = subject.convert(<<~HTML)
      <p>Winter is <b><span>coming<p> again</p></span></b></p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Winter is coming again'
      inline_style 'BOLD', 10..21
    }
  end

  it 'encodes nested, duplicate styles' do
    raw_draftjs = subject.convert(<<~HTML)
      <p><b><i><u>First <b><i><u>second</u></i></b></u></i></b></p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'First second'
      inline_style 'BOLD', 0..11
      inline_style 'ITALIC', 0..11
      inline_style 'UNDERLINE', 0..11
    }
  end

  it 'ignores `table` tags, and treats `tr` as a block-starting element' do
    raw_draftjs = subject.convert(<<~HTML)
      <table><thead><tr>Header line 1</tr><tr>Header line 2</tr></thead>
             <tbody><tr>Body line 1<table><tr>Body line 2</tr></table></tr></tbody></table>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Header line 1'
      text_block 'Header line 2'
      text_block 'Body line 1'
      text_block 'Body line 2'
    }
  end

  it 'renders fully-styled, nested list content as a single block' do
    raw_draftjs = subject.convert(<<~HTML)
      <div><strong>
        <ul>
          <li>Item 1</li>
        </ul>
      </strong></div>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unordered-list-item', 'Item 1'
      inline_style 'BOLD', 0..5
    }
  end

  it 'gracefully "ignores" deeply-nested, same-style style tags _around_ block tags' do
    raw_draftjs = subject.convert(<<~HTML)
      <div>
        <b>
          <font color="black">
            <b></b>
            <p dir="ltr">Line 1</p>
          </font>
        </b>
      </div>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unstyled', 'Line 1'
      inline_style 'BOLD', 0..5
    }
  end

  it 'creates multiple, non-overlapping style ranges' do
    raw_draftjs = subject.convert(<<~HTML)
      <p><i>Winter</i> <i>is</i> <i>coming</i></p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unstyled', 'Winter is coming'
      inline_style 'ITALIC', 0..5
      inline_style 'ITALIC', 7..8
      inline_style 'ITALIC', 10..15
    }
  end

  it 'treats `divs` as block elements' do
    raw_draftjs = subject.convert(<<~HTML)
      <div>Winter <div>is</div> coming</div>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Winter '
      text_block 'is'
      text_block ' coming'
    }
  end

  it 'does not explode with nested `td` elements' do
    raw_draftjs = subject.convert(<<~HTML)
      <div>
        <table>
          <tr>
            <td>Winter
              <div>
                <table>
                  <tr>
                    <td>is coming</td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>
        </table>
      </div>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unstyled', "Winter"
      typed_block 'unstyled', "is coming"
    }
  end

  it 'consumes text inside top-level `div` elements' do
    raw_draftjs = subject.convert(<<~HTML)
      <div class="elementToProof">Hi All,</div>
      <p>Help</p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Hi All,'
      text_block 'Help'
    }
  end

  it 'supports block-level elements inside `div`' do
    raw_draftjs = subject.convert(<<~HTML)
      <div class="WordSection1">
        <p>Best,</p>
        <p>Yours truly</p>
      </div>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Best,'
      text_block 'Yours truly'
    }
  end

  it 'adds a space (" ") character for empty tags that are user-converted to entities' do
    options = {
      node_to_entity: ->(tagname, _content, _attributes) {
        if tagname == 'span'
          { type: 'REPLACED', data: {} }
        end
      }
    }
    subject = described_class.new(options)
    raw_draftjs = subject.convert(<<~HTML)
      <p>Lookie here! <span></span> three spaces before me</p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Lookie here!   three spaces before me'
      apply_entity 'REPLACED', 13..13
    }
  end

  it 'converts `code` tags inside block elements to an inline style' do
    raw_draftjs = subject.convert(<<~HTML)
      <p>Lookie here! <code>puts "some code"</code></p>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block 'Lookie here! puts "some code"'
      inline_style 'CODE', 13..28
    }
  end

  it 'properly attributes entities to the correct block when a pending block is broken up by newlines' do
    raw_draftjs = subject.convert(<<~HTML)
      <div dir="ltr">
        <a href="http://example1.example.com">example 1</a>
        <br/>
        <a href="http://example2.example.com">example 2</a>
        <br>
        <div><br></div>
        <div>test<br/></div>
        <a href="http://example3.example.com">example 3</a>
      </div>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      text_block "example 1"
      apply_entity 'LINK', 0..8, mutability: 'MUTABLE', data: { href: 'http://example1.example.com' }

      text_block "example 2"
      apply_entity 'LINK', 0..8, mutability: 'MUTABLE', data: { href: 'http://example2.example.com' }

      text_block ""
      text_block "test"

      text_block "example 3"
      apply_entity 'LINK', 0..8, mutability: 'MUTABLE', data: { href: 'http://example3.example.com' }
    }
  end

  it 'properly creates lists inside tables' do
    subject = described_class.new
    raw_draftjs = subject.convert(<<~HTML)
    <table>
      <tr>
        <td>
          <ul><li>item 1</li>
          <ul><li>item 1.1</li></ul></ul>
        </td>
      </tr>
    </table>
    HTML

    expect(raw_draftjs).to eq_raw_draftjs {
      typed_block 'unordered-list-item', 'item 1'
      typed_block 'unordered-list-item', 'item 1.1', depth: 1
    }
  end
end
