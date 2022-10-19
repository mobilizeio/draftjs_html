# frozen_string_literal: true

RSpec.describe DraftjsHtml, 'DraftjsHtml - HTML Injection protection' do
  it 'auto-escapes HTML tags that are passed as text' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block '<b>unsafe</b>'
    end

    html = described_class.to_html(raw_draftjs)

    expect(html).to eq '<p>&lt;b&gt;unsafe&lt;/b&gt;</p>'
  end

  it 'protects from injection in entities' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block 'afterward'
      apply_entity 'mention', 0..8, data: { url: 'https://example.com/users/1' }
    end

    html = described_class.to_html(raw_draftjs, options: {
      entity_style_mappings: {
        mention: ->(*) {
          "<a>will-be-escaped</a>"
        },
      },
    })

    expect(html).to eq <<~HTML.strip
      <p>&lt;a&gt;will-be-escaped&lt;/a&gt;</p>
    HTML
  end

  it 'protects from injection in inline-style renderers' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block 'afterward'
      inline_style 'BOLD', 0..8
    end

    html = described_class.to_html(raw_draftjs, options: {
      inline_style_renderer: ->(*) {
        "<a>will-be-escaped</a>"
      },
    })

    expect(html).to eq <<~HTML.strip
      <p>&lt;a&gt;will-be-escaped&lt;/a&gt;</p>
    HTML
  end

  it 'protects from injection with nested styles and entities' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block 'afterward'
      inline_style 'BOLD', 0..8
      apply_entity 'mention', 0..8, data: { url: 'https://example.com/users/1' }
    end

    html = described_class.to_html(raw_draftjs, options: {
      entity_style_mappings: {
        'mention' => ->(*) {
          "<a>will-be-escaped</a>"
        },
      },
      inline_style_renderer: ->(*) {
        "<a>will-be-escaped</a>"
      },
    })

    expect(html).to eq <<~HTML.strip
      <p>&lt;a&gt;will-be-escaped&lt;/a&gt;</p>
    HTML
  end

  it 'allows specifying entity content as a DraftjsHtml::Node' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block '@branstark'
      apply_entity 'mention', 0.., data: { url: 'https://example.com/users/1' }
    end

    html = described_class.to_html(raw_draftjs, options: {
      entity_style_mappings: {
        'mention' => ->(entity, content, *) {
          DraftjsHtml::Node.new('a', { href: entity.data['url'] }, content)
        },
      },
    })

    expect(html).to eq <<~HTML.strip
      <p><a href="https://example.com/users/1">@branstark</a></p>
    HTML
  end

  it 'allows specifying entity content as a Nokogiri::XML::Node' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block '@jonsnow'
      apply_entity 'mention', 0.., data: { url: 'https://example.com/users/1' }
    end

    html = described_class.to_html(raw_draftjs, options: {
      entity_style_mappings: {
        'mention' => ->(entity, content, document) {
          Nokogiri::XML::Node.new('a', document).tap do |node|
            node.content = content
            node['href'] = entity.data['url']
          end
        },
      },
    })

    expect(html).to eq <<~HTML.strip
      <p><a href="https://example.com/users/1">@jonsnow</a></p>
    HTML
  end

  it 'allows specifying inline style content as a DraftjsHtml::Node' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block '@catlynstark'
      inline_style 'BOLD', 0..11
    end

    html = described_class.to_html(raw_draftjs, options: {
      inline_style_renderer: ->(_style_names, content, *) {
        DraftjsHtml::Node.new('b', {}, content)
      },
    })

    expect(html).to eq <<~HTML.strip
      <p><b>@catlynstark</b></p>
    HTML
  end

  it 'allows specifying entity content as a Nokogiri::XML::Node' do
    raw_draftjs = DraftjsHtml::Draftjs::RawBuilder.build do
      text_block '@rickardstark'
      inline_style 'BOLD', 0..12
    end

    html = described_class.to_html(raw_draftjs, options: {
      inline_style_renderer: ->(_style_names, content, document) {
        Nokogiri::XML::Node.new('b', document).tap do |node|
          node.content = content
        end
      },
    })

    expect(html).to eq <<~HTML.strip
      <p><b>@rickardstark</b></p>
    HTML
  end
end
