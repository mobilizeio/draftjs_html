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

DraftjsHtml.to_html(raw_draftjs, {
  entity_style_mappings:  {
    link: ->(entity, content) {
      %Q{<a href="#{entity.data['url']}">#{content}</a>}
    },
  },
}) # => <p>Hello </p>
```

Almost all of the options support Procs (or otherwise `.call`-ables) to provide
flexibility in the conversion process. As the library uses Nokogiri to generate
HTML, it's also possible to return `Nokogiri::Node` objects or String objects.

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
