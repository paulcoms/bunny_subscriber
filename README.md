# BunnySubscriber

Simple RabbitMQ subscriber for ruby and rails applications using
[Bunny](https://github.com/ruby-amqp/bunny). Heavily inspired by
[Sneakers](https://github.com/jondot/sneakers), it provides a simple way to
connect to RabbitMQ as a subscriber.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bunny_subscriber'
```

## Basic usage

To add a consumer, just include the module `BunnySubscriber::Consumer`, and define the method `process_event`:

```ruby
class SomeConsumer
  include BunnySubscriber::Consumer

  subscriber_options queue_name: 'some.rabbit.queue'

  def process_event(message)
    # Do some work
  end
end
```

You can optionally describe a `queue_exchange` which the queue will bind with, and if you want exchange to exchange functionality you can proved `queue_exchange` _and_ `master_exchange` details. The exchanges are `fanout` types with `bind` set to `true`.

```ruby
class SomeConsumer
  include BunnySubscriber::Consumer

  subscriber_options queue_name: 'some.rabbit.queue'
                     queue_exchange: 'some.rabbit.queue.exchange'
                     master_exchange: 'some.rabbit.exchange'

  def process_event(message)
    # Do some work
  end
end
```

To start the server, just run:

```bash
bundle exec bunny_subscriber
```

## Configuration

By default, `BunnySubscriber` loads the file `./config/bunny_subscriber.yml` for configurations. But that path can be specified on the command line as follows:

```
bundle exec bunny_subscriber -c some/path.yml
```

The options available in the yaml, by environment, are:

```yml
default: &default
  host: 127.0.0.1
  port: 5672
  user: guest
  pass: guest
  vhost: /
  heartbeat: 30
  consumer_classes:
    - SomeConsumer

development:
  <<: *default
  workers: 2

production:
  <<: *default
  host: some.host
  vhost: /other
  user: <%= ENV['user_in_env'] %>
  pass: <%= ENV['password_in_env'] %>
  workers: 5
  daemonize: true
```

| Parameter name   | Type    | Description                                                                              | Default                     |
| ---------------- | ------- | ---------------------------------------------------------------------------------------- | --------------------------- |
| host             | String  | RabbitMQ host                                                                            | 127.0.0.1                   |
| port             | Integer | RabbitMQ port                                                                            | 5672                        |
| user             | String  | RabbitMQ user                                                                            | guest                       |
| pass             | String  | RabbitMQ password                                                                        | guest                       |
| vhost            | String  | RabbitMQ virtual host                                                                    | /                           |
| heartbeat        | Integer | Standard RabbitMQ server heartbeat                                                       |                             |
| workers          | Integer | Number of process (not threads) that runs the server                                     | 1                           |
| daemonize        | Boolean | Run server in background or not                                                          | false                       |
| logger_path      | String  | Logger output file when running as daemon                                                | ./log/bunny_subscriber.log  |
| pid_path         | String  | File that saves the current process master id                                            | ./pids/bunny_subscriber.pid |
| boot_path        | String  | Path to a ruby script that initialize the environment. The default works for a Rails app | ./config/environment        |
| consumer_classes | Array   | Specified which consumers you want to consider                                           | All defined consummers      |

## Command line options

For all the command line options, run:

```
bundle exec bunny_subscriber --help
```

## Using without Rails

By default, `BunnySubscriber` works with Rails. If you want to use it without Rails, or do not want to load the entire Rails environment (usefull if you want to create consumers that only enqueue jobs using other frameworks), just change the `boot_path` and load what you want in that script.
