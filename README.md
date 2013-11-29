# Asynchronic

[![Gem Version](https://badge.fury.io/rb/asynchronic.png)](https://rubygems.org/gems/asynchronic)
[![Build Status](https://travis-ci.org/gabynaiman/asynchronic.png?branch=master)](https://travis-ci.org/gabynaiman/asynchronic)
[![Coverage Status](https://coveralls.io/repos/gabynaiman/asynchronic/badge.png?branch=master)](https://coveralls.io/r/gabynaiman/asynchronic?branch=master)
[![Code Climate](https://codeclimate.com/github/gabynaiman/asynchronic.png)](https://codeclimate.com/github/gabynaiman/asynchronic)
[![Dependency Status](https://gemnasium.com/gabynaiman/asynchronic.png)](https://gemnasium.com/gabynaiman/asynchronic)

DSL for asynchronic pipeline using queues over Redis

## Installation

Add this line to your application's Gemfile:

    gem 'asynchronic'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install asynchronic

## Usage

### Basic usage

    class Job
      extend Asynchronic::Pipeline
      
      step :step_name do
        ...
      end
    end

    Job.run

    Asynchronic::Worker.start

### Enque job in specific queue

    class Job
      extend Asynchronic::Pipeline
      
      queue :queue_name
      
      step :step_name do
        ...
      end
    end

    Job.run

    Asynchronic::Worker.start :queue_name

### Pipeline with shared context

    class Job
      extend Asynchronic::Pipeline

      step :first do |ctx|
        ctx[:c] = ctx[:a] + ctx[:b]
        100
      end

      step :second do |ctx, input|
        input * ctx[:c] # 300
      end
    end

    Job.run a: 1, b: 2

    Asynchronic::Worker.start

### Specify queue for each step

    class Job
      extend Asynchronic::Pipeline
      
      step :first_queue, queue: :queue1 do
        ...
      end
      
      step :second_queue, queue: ->(ctx){ctx[:dynamic_queue]} do
        ...
      end
    end

    Job.run dynamic_queue: :queue2

    [:queue1, :queue2].map do |queue|
      Thread.new do
        Asynchronic::Worker.start queue
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
