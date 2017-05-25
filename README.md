# Capsicum

A simple FFI wrapper around the [Capsicum](https://wiki.freebsd.org/Capsicum)
OS capability and sandbox framework.


## Installation

A Capsicum-enabled OS is, of course, required.  FreeBSD 10+ (or derivative),
possibly [capsicum-linux](http://capsicum-linux.org/).

Add this line to your application's Gemfile:

```ruby
gem 'capsicum'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capsicum


## Usage

Basic synopsis:

```ruby
Capsicum.sandboxed?    # => false
Capsicum.enter!        # => true
Capsicum.sandboxed?    # => true

File.new("/dev/null")  # => Errno::ECAPMODE: Not permitted in capability mode @ rb_sysopen - /dev/null
TCPSocket.new("0", 80) # => Errno::ECAPMODE: Not permitted in capability mode - connect(2) for "0" port 80
`rm -rf /`             # => Errno::ECAPMODE: Not permitted in capability mode - rm
system "rm -rf /"      # => nil
require 'time'         # => LoadError: cannot load such file -- time
```

i.e. anything that involves opening a file, connecting a socket, or executing a
program is verboten.  Kinda.

On fork-capable Rubies, you can also do this:

```ruby
Capsicum.sandboxed?   # => false

status = Capsicum.within_sandbox do
  Capsicum.sandboxed? # => true
  exit 42
end

Capsicum.sandboxed?   # => false
status.exitstatus     # => 42
```

The result is a Process::Status object.


## But How Can I Get Anything Done?

Open your files and sockets before entering the sandbox.  If you have a
`TCPServer` open, for example, you can still call `#accept` on it, so a useful
server could conceivably run within it.

You *can* open new files, but this requires access to *at() syscalls.  If Ruby
supported them, it might look something like this:

```ruby
dir = Dir.open("/path/to/my/files")

Capsicum.enter!

file = File.openat(dir, "mylovelyfile")
File.renameat(dir, "foo", dir, "bar")
File.unlinkat(dir, "moo")
```

Unfortunately, it doesn't.  See https://bugs.ruby-lang.org/issues/10181

You may consider spawning off workers, maintaining a privileged master process,
and using IPC to communicate with them.

## Todo

Wrap Casper to provide DNS services, additional rights controls, etc.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Freaky/ruby-capsicum.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

