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
### Using the API class `Chatrix::Matrix`
This implementation is currently very basic and exposes all the endpoints
in the `Matrix` class. Example usage:

```ruby
# Uses the standard matrix.org homeserver
api = Chatrix::Matrix.new 'my secret token'

# Join may raise ForbiddenError if client does not have permission
# to join the room
if id = api.rooms.actions.join '#myroom:myserver.org'
  api.rooms.actions.send_message id, 'Hello everyone!'
end
```

Currently there is no asynchronous calls or built-in handling of
rate-limiting.

### Using the client class `Chatrix::Client`
The client class works as a wrapper around the raw API calls to make working
with the API a little easier. It uses the [`wisper`][wisper] gem to broadcast
state changes.

```ruby
# When setting up with an access token, there is no way to obtain your own
# user ID through the API, so it has to be supplied manually.
client = Chatrix::Client.new 'my token', 'my user id'

# This will spawn a new thread that continously syncs against the homeserver
# to check for new events. It can be stopped by calling Client#stop_syncing.
client.start_syncing

# Set up a listener for when a message arrives
client.on(:room_message) do |room, message|
  puts "(#{room}) #{message.sender}: #{message.body}"
end

# We can also listen to messages in a specific room by subscribing to the
# timeline of that room.
myroom = client.get_room '#myroom:myserver.org'
myroom.timeline.on(:message) do |room, message|
  # Reply with a "Pong!" if someone sends a message starting
  # with the word "ping", but don't reply to ourselves.
  if message.body.match(/^\bping\b/i) && message.sender != client.me
    room.messaging.send_message 'Pong!'
  end
end

# Permissions and room actions can be used with relative ease.
myroom.timeline.on(:message) do |room, message|
  if message.body.match(/^!kickme$/i) && message.sender != client.me
    if room.state.permissions.can? message.sender, :kick
      room.admin.kick message.sender, 'They asked for it'
    else
      room.messaging.send_message "You do not have kick privileges, #{message.sender}"
    end
  end
end
```

When subscribing to an event, make sure to
[not return inside the block][no-return-blocks].

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

[wisper]: https://github.com/krisleech/wisper
[no-return-blocks]: http://product.reverb.com/2015/02/28/the-strange-case-of-wisper-and-ruby-blocks-behaving-like-procs/
