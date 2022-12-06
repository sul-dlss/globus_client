[![Gem Version](https://badge.fury.io/rb/globus_client.svg)](https://badge.fury.io/rb/globus_client)
[![CircleCI](https://circleci.com/gh/sul-dlss/globus_client.svg?style=svg)](https://circleci.com/gh/sul-dlss/globus_client)
[![Code Climate](https://codeclimate.com/github/sul-dlss/globus_client/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/globus_client)
[![Code Climate Test Coverage](https://api.codeclimate.com/v1/badges/8e6bf1a5d3fc86a6fbd0/test_coverage)](https://codeclimate.com/github/sul-dlss/globus_client/test_coverage)

# Globus::Client

Globus::Client is a Ruby gem that acts as a client to the RESTful HTTP APIs provided by the [Globus service](https://docs.globus.org/api/).

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add globus_client

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install globus_client

## Usage

For one-off requests:

```ruby
require 'globus/client'

# NOTE: The settings below live in the consumer, not in the gem.
client = Globus::Client.configure(
  client_id: Settings.globus.client_id,
  client_secret: Settings.globus.client_secret,
  uploads_directory: Settings.globus.uploads_directory,
  transfer_endpoint_id: Settings.globus.transfer_endpoint_id
)
client.mkdir(user_id: 'mjgiarlo', work_id: 1234, work_version: 1)

result = client.user_exists?('mjgiarlo')
```

You can also invoke methods directly on the client class, which is useful in a
Rails application environment where you might initialize the client in an
initializer and then invoke client methods in many other contexts where you want
to be sure configuration has already occurred, e.g.:

```ruby
# config/initializers/globus_client.rb
Globus::Client.configure(
  client_id: Settings.globus.client_id,
  client_secret: Settings.globus.client_secret,
  uploads_directory: Settings.globus.uploads_directory,
  transfer_endpoint_id: Settings.globus.transfer_endpoint_id
)

# app/services/my_globus_service.rb
# ...
def create_user_directory
  Globus::Client.mkdir(user_id: 'mjgiarlo', work_id: 1234, work_version: 1)
end
# ...
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Integration Testing

To test that the gem works against the Globus APIs, run `api_test.rb` via:

```shell
# NOTE: This is bash syntax, YMMV
$ export GLOBUS_CLIENT_ID=$(vault kv get -field=content puppet/application/sdr/globus/{prod|qa|stage}/client_id)
$ export GLOBUS_CLIENT_SECRET=$(vault kv get -field=content puppet/application/sdr/globus/{prod|qa|stage}/client_secret)
$ export GLOBUS_ENDPOINT=$(vault kv get -field=content puppet/application/sdr/globus/{prod|qa|stage}/endpoint_uuid)
$ export GLOBUS_UPLOADS_DIRECTORY=from_shared_configs
# NOTE: The three args below are a user ID, a work ID, and a work version
$ ./api_test.rb mjgiarlo 987 1

Initial directory permissions: rw
Number of files in directory: 2
Total size of files in directory: 66669
Final directory permissions: r
```

Inspect the output and compare it to what you see in Globus Personal Connect to determine if behavior is correct.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sul-dlss/globus_client.
