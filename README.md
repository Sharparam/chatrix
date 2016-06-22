ratrix
======

A Ruby implementation of the [Matrix][matrix] API.

## License

Copyright (c) 2016 by Adam Hellberg.

ratrix is licensed under the [MIT License][license-url], see the file
`LICENSE` for more information.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ratrix'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ratrix

## Usage

This implementation is currently very basic and exposes all the endpoints
in the `Matrix` class. Example usage:

```ruby
# Uses the standard matrix.org homeserver
rat = Ratrix::Matrix.new 'my secret token'

if id = rat.join '#myroom:myserver.org'
  rat.send_message id, 'Hello everyone!'
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests. You can also run `bin/console`
for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on [GitHub][issues].

[project]: https://github.com/Sharparam/ratrix
[issues]: https://github.com/Sharparam/ratrix/issues
[matrix]: http://matrix.org
[license-url]: http://opensource.org/licenses/MIT
