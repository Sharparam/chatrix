chatrix
=======

[![Gem version][gem-badge-img]][gem-badge]
[![Dependency status][gemnasium-img]][gemnasium]
[![Build status][travis-img]][travis]
[![Code climate][cc-img]][cc]
[![Coverage][coverage-img]][coverage]
[![Inline docs][inch-img]][inch]

A Ruby implementation of the [Matrix][matrix] API.

## License

Copyright (c) 2016 by Adam Hellberg.

chatrix is licensed under the [MIT License][license-url], see the file
`LICENSE` for more information.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chatrix'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install chatrix

## Usage

This implementation is currently very basic and exposes all the endpoints
in the `Matrix` class. Example usage:

```ruby
# Uses the standard matrix.org homeserver
api = Chatrix::Matrix.new 'my secret token'

# Join may raise ForbiddenError if client does not have permission
# to join the room
if id = api.join '#myroom:myserver.org'
  api.send_message id, 'Hello everyone!'
end
```

Currently there is no asynchronous calls or built-in handling of
rate-limiting.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests. You can also run `bin/console`
for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on [GitHub][issues].

[project]: https://github.com/Sharparam/chatrix
[issues]: https://github.com/Sharparam/chatrix/issues
[matrix]: http://matrix.org
[license-url]: http://opensource.org/licenses/MIT

[gem-badge]: https://badge.fury.io/rb/chatrix
[gem-badge-img]: https://badge.fury.io/rb/chatrix.svg
[gemnasium]: https://gemnasium.com/github.com/Sharparam/chatrix
[gemnasium-img]: https://gemnasium.com/badges/github.com/Sharparam/chatrix.svg
[travis]: https://travis-ci.org/Sharparam/chatrix
[travis-img]: https://travis-ci.org/Sharparam/chatrix.svg?branch=master
[cc]: https://codeclimate.com/github/Sharparam/chatrix
[cc-img]: https://codeclimate.com/github/Sharparam/chatrix/badges/gpa.svg
[coverage]: https://codeclimate.com/github/Sharparam/chatrix/coverage
[coverage-img]: https://codeclimate.com/github/Sharparam/chatrix/badges/coverage.svg
[inch]: http://inch-ci.org/github/Sharparam/chatrix
[inch-img]: http://inch-ci.org/github/Sharparam/chatrix.svg?branch=master
