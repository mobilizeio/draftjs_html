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
    abc: ->(entity, content, *) {
      DraftjsHtml::Node.new('a', { href: "https://example.com/?id=#{entity.data['user_id']}" }, content)
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

#### `squeeze_newlines`

Often times, we'll get text in our blocks that will generate unexpected HTML.
Most of this is caused by whitespace.
You can use the `squeeze_newlines` option to collapse consecutive newline/CRLF characters to one, resulting in a single `<br>` tag.
Defaults to `false`.

```ruby

```

#### `:entity_style_mappings`

Allows the author to specify special mapping functions for entities.
By default, we render `LINK` and `IMAGE` entities using the standard `<a>` and `<img>` tags, respectively.
The author may supply a `call`-able object that returns a `DraftjsHtml::Node`-able (or similar).
If returned a String, it's assumed this content is plaintext (or otherwise unsafe) and its content will be coerced to plaintext.
See the section on HTML Injection protection for more details.

#### `:block_type_mapping`

You may wish to override the default HTML tags used for DraftJS block types.
By default, we convert block types to tags as defined by `DraftjsHtml::ToHtml::BLOCK_TYPE_TO_HTML`.
These may be overridden and appended to, like so:

```ruby
DraftjsHtml.to_html(raw_draftjs, options: {
  squeeze_newlines: true,
})

# Given a DraftJS block like: `{ text: 'Hi!\n\n\nWelcome to Westeros!\n\n\n'}`
# This would generate `<p>Hi!<br>Welcome to Westeros!<br></p>`
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

You may also add attributes to tags created by `inline_style_mapping`s by using a two element array.
The first element should be the tagname and the second argument a hash of attributes to values, like this:

```ruby

DraftjsHtml.to_html(raw_draftjs, options: {
  inline_style_mapping: {
    'BOLD' => ['strong', style: 'font-weight: 900'],
  },
})
```

# This would generate <strong> tags instead of <b> tags around ranges of `BOLD` inline styles.

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
    Nokogiri::XML::Node.new('pre', document).tap do |node|
      node.content = content
    end
  },
})

# This would use the default inline style rendering UNLESS the *only* applied style for this range was "CUSTOM"
```

#### HTML Injection protection

Working with user-generated content can be a dangerous thing.
While it allows for a lot of flexibility, it also creates some potential attack vectors that you need to be aware of.
We try to take a "safe by default" stance with this library, and not generate HTML that could be dangerous when we know better.

To facilitate this, we require a little work from you, dear programmer.
Namely, when specifying special algorithms for generating entities or inline styles, you need to help us keep you safe.
You can do this by returning a `Nokogiri::XML::Node` or `DraftjsHtml::Node` from any functions you provide that generate HTML.
This is similar to Ruby on Rails' `#to_html` method, but rather than a monkeypatch, we chose to provide a "marker class" (classes) that we know are safe.
These classes will handle escaping, encoding, and otherwise "safe generation" for you.
If you, on the other hand, return a bare `String` from one of the custom render functions, we assume it's _unsafe_ and encode it.

That is, a function like this:
```ruby
->(entity, content, document) do
  "<p>hi!</p>"
end
# will become an HTML-entity escaped string (e.g. "&lt;p&gt;hi!&lt;/p&gt;")
```

Where, a function like this:
```ruby
->(entity, content, document) do
  DraftjsHtml::Node.new('p', {}, 'hi!')
end
# will nest HTML nodes as you probably want (e.g. "<p>hi!</p>")
```

### FromHtml (beta)

As an experiment, this gem is providing the ability to convert from HTML to raw
DraftJS JSON. You can explore this behavior with the following snippet:

```ruby
DraftjsHtml.from_html("<p>Hello!</p>") # => { "blocks" => [{ "text": "Hello!", "type" => "unstyled" } ] }
```

There are some known limitations with this approach, but, if you're just trying
to get started, it may be good enough for you. Contributions and issue reports
are welcome and encouraged.

#### `:node_to_entity:`

This `FromHtml` option allows the user to specify how a particular node is
converted to a DraftJS entity. By default, the library converts `img` and `a`
tags to `IMAGE` and `LINK` entities, respectively. If you specify this option,
you override the existing behavior and must define those conversions yourself.

The option expects a `callable` (`proc`, `lambda`, etc) that receives 3 arguments:

- tagname (e.g. `a`) - always downcased
- content - the text content inside the tag
- HTML attributes - any HTML attributes on the tag as a Hash (string keys)

The callable should return a Hash with symbol keys. The supported values are:

- `type` (required)
  - the entity "type" or name
- `mutability` (optional, default `'IMMUTABLE'`)
  - either 'MUTABLE', 'IMMUTABLE', or 'SEGMENTED'
- `atomic` (optional, default `false`)
  - when true, creates a new "atomic" block for this entity rather than apply 
    the entity to the current range
- `data` (optional, default `{}`)
  - an arbitrary data-bag (Hash) of entity data

#### `:is_semantic_markup:`

Defaults to `true`.

By setting to `false`, the user is stating they want to treat `div` tags as semantic,
block-level tags. In some markup (emails, for example), there are no semantic tags
(read, no `p` tags), so the only indications of whitespace and structure come from
`div` tags. This flag will flush content wrapped in a `div` as a DraftJS block. 

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
