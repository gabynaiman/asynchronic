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

    class SingleStepJob
      extend Asynchronic::Pipeline
      step :step_name do
        Registry.add :single_step_job
      end
    end

    class TwoStepsWithSpecificQueueJob
      extend Asynchronic::Pipeline
      queue :specific_queue
      step :first do |ctx|
        ctx[:value2] = ctx[:value1] / 2
        Registry.add ctx[:value1] + 1
      end
      step :second do |ctx, input|
        Registry.add input * ctx[:value2]
      end
    end

    class MultipleQueuesJob
      extend Asynchronic::Pipeline
      step :first_queue, queue: :queue1 do
        Registry.add :first_queue
      end
      step :second_queue, queue: ->(ctx){ctx[:dynamic_queue]} do
        Registry.add :second_queue
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
