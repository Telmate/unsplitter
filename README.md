# Unsplitter*
  *For split brain databases

## Installation

* Jruby
* One copy next to each target database
* When running, consider the Primary as the remote master database


## Usage

    $ bundle exec bin/unsplitter -h
    
  Sample run, sync table messages:
  
    $ bundle exec bin/unsplitter -c ~/app/config/database.yml messages 

## Contributing

1. Fork it ( https://github.com/Telmate/unsplitter/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
