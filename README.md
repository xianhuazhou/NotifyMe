## Introduction

NotifyMe is a script running as a cronjob in background,  can take care more than one tasks (by Ruby Threads), and push the results(error messages usually) to different endpoints(stdout, mail, file etc.) with different formats such as xml, json, csv etc. if something goes wrong. It depends on what's you need.

## Installation

gem install notifyme

## Run it (with root permission)

### run in the background

    # notifyme_daemon start --(double dash here) /absolute/path/to/your/notifyme_config.rb

### debug (use Ctrl + C to stop it)

    # notifyme_daemon run --(double dash here) /absolute/path/to/your/notifyme_config.rb

### stop

    # notifyme_daemon stop

## Examples

### Check HTTP Server (e.g. Nginx)

```ruby
  require 'socket'

  NotifyMe::Start.config do
    # output to the console
    log :stdout

    # output format is text
    log_format :text

    # define the task 
    task :check_http_server do |t| 

      # running every 5 seconds
      t.sleep_time = 5 

      # check command
      t.command = lambda { check :tcp, :host => 'localhost', :port => 80 }

      # if the server is not running, the restart_command will be executed
      t.restart_command = lambda { %x{/etc/init.d/nginx start} }
    end 

  end
```

### Check the "cupsd" process (from "ps -e")

```ruby
  NotifyMe::Start.config do
    log :stdout
    log_format :json 
    task :check_cupsd do |t| 
      t.sleep_time = 5 
      t.command = lambda {
        if %x{ps -e}.include? " cupsd"
          nil 
        else
          "Warnning: the process cupsd is not running!"
        end 
      }   
      t.restart_command = lambda { `/etc/init.d/cups start` }   
    end 
  end
```

More please check the notifyme_config.rb file.

## built-in check functions (since v1.0.0)

So far, NotifyMe has 3 built-in check functions, which are "check :process", "check :tcp" and "check :http"(since v1.0.1), e.g.:

```ruby
t.command = lambda { check :process, :name => "nginx"}
t.command = lambda { check :tcp, :host => "localhost", :port => 80}
t.command = lambda { check :http, :url => "http://github.com", :include => 'Social Coding'}
```

## Add custom check functions into the "~/.notifyme/check.rb" file (since v1.0.0)

You also can write your own check functions into the `~/.notifyme/check.rb` file, e.g.

```ruby
# file: ~/.notifyme/check.rb
class NotifyMe::Check
  class << self
    def mysql(args = {}) 
      require 'mysql2'
      Mysql2::Client.new args 
    end 
  end 
end
```

Then you can use the `check :mysql` function like:

```ruby
task :check_mysql do |t|
  t.sleep_time = 5
  t.command = lambda { check :mysql, :host => 'localhost', :username => 'root', :password => 'pa$$' }
  t.restart_command = lambda { `/etc/init.d/mysqld restart` }
end
```

## Add tasks into the "~/.notifyme/check/" directory (since v1.0.0)

Instead of put all of tasks into the `notifyme_config.rb` file. you can also put them into the `~/.notifyme/check/` directory, one task one file, it's easy to manage them if you have too many things to check.
e.g.

```ruby
# file: ~/.notifyme/check/redis.rb

def check_redis(t)
  t.sleep_time = 5
  t.command = lambda { check :tcp, :host => 'localhost', :port => 6379 }
end
```

## Output

The output from every task's command will be processed (send to endpoints such as email, console etc.) only if the output is not empty, otherwise do nothing.

## Version

v 1.0.2

## TODO

Add some SPECS
