# Unsplitter*
  *For split brain databases

 
Runs a long (for big tables) streaming query against a primary database that queues 
parallel compares and updates to a secondary database.

Its intended that you pick your favorite primary to unsplit, then run the unsplit in reverse.


Step 1:

    Primary <-- replication --> Secondary
       \                           \|/
        \---------------------> unsplitter


Step 2:
    
    Secondary <-- replication --> Primary
       \|/                           /
    unsplitter <--------------------/
        



## Installation

* Jruby
* One copy next to each target database
* When running, consider the Primary as the remote master database


## Usage

    $ bundle exec bin/unsplitter -h
    
  Sample run, sync table messages:
  
    $ bundle exec bin/unsplitter -c ~/app/config/database.yml messages 

## Caveats

To update/insert missing different records, this script uses REPLACE commands.

For master-master:
    
    TODO (not yet supported): option to SET sql_log_bin = 0

For a topology like (supported):

    master - master
       /       \
    slave     slave


Prerequisite slave skip config between masters is:

    slave-skip-errors = 1062,1032,1452

1062 - Duplicate entry
1032 - Can't find record
1452 - Cannot add or update a child row: a foreign key constraint fails



## Sample database.yml
    
    db_primary:
      adapter: mysql
      database: blog_db
      host: master1
      pool: 20
      username: readwriteUser
      password: password
    
    db_secondary:
      adapter: mysql
      database: blog_db
      host: master2
      pool: 20
      username: readwriteUser
      password: password

## Contributing

1. Fork it ( https://github.com/Telmate/unsplitter/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
