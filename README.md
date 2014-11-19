# SimCtl

This is a Ruby wrapper for Xcode's `simctl` command line, designed
to simplify scripting an iOS Simulator. 

This project is just getting started, so consider it alpha quality.

In Ruby, to create a simulator instance, and add some photos to it, you would:
```
device = SimCtl.create_or_find('PhotoTest')
device.boot
device.add_photos Dir['/Users/you/photos/*.jpg']
device.shutdown
```

We're at the stage right now where reading through the (small) source is probably your
best bet for documentation.

## Installation

Add this line to your application's Gemfile:

    gem 'SimCtl'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install SimCtl
