# DraftjsHtml

[![Gem Version](https://badge.fury.io/rb/draftjs_html.svg)](https://badge.fury.io/rb/draftjs_html)
[![Build Status](https://app.travis-ci.com/dugancathal/draftjs_html.svg?branch=main)](https://app.travis-ci.com/dugancathal/draftjs_html)

This gem provides conversion utilities between "raw" [DraftJS] JSON and HTML.
My team and I have found a need on many occasions to manipulate and convert
DraftJS on our Ruby backend - this library is the result.

[DraftJS]: https://draftjs.org/

## Installation

Add this line to your application's Gemfile:

```ruby gem 'draftjs_html' ```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install draftjs_html

## Usage

This gem aims to provide a very high-level API for conversion. The most
basic usage is:

```ruby
raw_draftjs = { 'blocks' => [{ 'text' => 'Hello world!' }], 'entityMap' => {} }
DraftjsHtml.to_html(raw_draftjs) # => <p>Hello world!</p>
```

Things can get more complicated as you have custom entities and/or inline
styles. If this is the case, you can supply various configuration options
to the top-level conversion method(s) for describing how to translate your
content. One example might look like:

```ruby
raw_draftjs = {
  'blocks' => [
    {
      'text' => 'Hello @Arya!',
      'entityRanges' => [{ 'key' => 'abc', 'offset' => 6, 'length' => 5 }],
    }
  ],
  'entityMap' => {
    'abc' => {
      'mutability' => 'IMMUTABLE',
      'type' => 'mention',
      'data' => {
        'user_id' => 123
      },
    },
  },
}

DraftjsHtml.to_html(raw_draftjs, options: {
  entity_style_mappings:  {
    abc: ->(entity, content) {
      %Q{<a href="https://example.com/?id=#{entity.data['user_id']}">#{content}</a>}
    },
  },
}) # => <p>Hello <a href="https://example.com/?id=123">@Arya</a></p>
```

Almost all of the options support Procs (or otherwise `.call`-ables) to provide
flexibility in the conversion process. As the library uses Nokogiri to generate
HTML, it's also possible to return `Nokogiri::Node` objects or String objects.

### ToHtml Options

#### `:encoding`

Specify the HTML generation encoding.
Defaults to `UTF-8`.

#### `:entity_style_mappings`

Allows the author to specify special mapping functions for entities.
By default, we render `LINK` and `IMAGE` entities using the standard `<a>` and `<img>` tags, respectively.
The author may supply a Proc object that returns any object Nokogiri can consume for adding to HTML.
This includes `String`, `Nokogiri::Document::Fragment`, and `Nokogiri::Document` objects.

#### `:block_type_mapping`

You may wish to override the default HTML tags used for DraftJS block types.
By default, we convert block types to tags as defined by `DraftjsHtml::ToHtml::BLOCK_TYPE_TO_HTML`.
These may be overridden and appended to, like so:

```ruby
DraftjsHtml.to_html(raw_draftjs, options: {
  block_type_mapping: {
    'unstyled' => 'span',
  },
})

# This would generate <span> tags instead of <p> tags for "unstyled" DraftJS blocks.
```

#### `:inline_style_mapping`

You may wish to override the default HTML tags used to render DraftJS `inlineStyleRanges`.
This works very similarly to `:block_type_mapping`, and the tags are defined by `DraftjsHtml::ToHtml::STYLE_MAP`.
These may be overridden and appended to, like so:

```ruby
DraftjsHtml.to_html(raw_draftjs, options: {
  inline_style_mapping: {
    'BOLD' => 'strong',
  },
})

# This would generate <strong> tags instead of <b> tags around ranges of `BOLD` inline styles.
```

#### `:inline_style_renderer`

If the direct mapping from `:inline_style_mapping` isn't enough, you can supply a custom function for rendering a style range.
This function, when provided, will be called with all applicable styles for a range, and the relevant content/text for that range.
It bears stressing that this `#call`-able will be called with *all* defined styles for the content/character range.
This means that by declaring this function, you take responsibility for handling _all_ styles for that range.
However, if you "return" `nil` (or `false-y`) from the proc, it will fallback to the standard "mapping" fucntionality.

```ruby
DraftjsHtml.to_html(raw_draftjs, options: {
  inline_style_renderer: ->(style_names, content) {
    next if style_names != ['CUSTOM']
    "<pre>#{content}</pre>"
  },
})

# This would use the default inline style rendering UNLESS the *only* applied style for this range was "CUSTOM"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/dugancathal/draftjs_html. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the [code of
conduct](https://github.com/dugancathal/draftjs_html/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DraftjsHtml project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/dugancathal/draftjs_html/blob/main/CODE_OF_CONDUCT.md).
