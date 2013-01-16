## Introduction

NotifyMe is a script running in background, it can take care more than one tasks (by Ruby Threads), and push the results(error messages usually) to different endpoints(stdout, mails, files etc.) with different formats such as xml, json, csv etc. if something went wrong. 

## Features

* Monitoring processes, if any of processes stopped for whatever reasons, it can notify you and restart the stopped processes automatically.
* Run programs in every x seconds as cron jobs.
* Checking tasks as Nagios does but without interface.

## Installation

    # gem install notifyme

## Initialize configuration

    # notifyme

    The command will create a "/root/.notifyme" directory and initialize some basic config files.

## Run it (with root permission)

### run in the background

    # notifyme_daemon start --(double dash here) /absolute/path/to/your/notifyme_config.rb

    or run it without config path if the path of your config file is "/root/.notifyme/notifyme_config.rb".

    # notifyme_daemon start

### debug (use Ctrl + C to stop it)

    # notifyme_daemon run --(double dash here) /absolute/path/to/your/notifyme_config.rb

### stop

    # notifyme_daemon stop

## Examples

### Check HTTP Server (e.g. Nginx)

```ruby
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

## Add custom check functions into the "/root/.notifyme/check.rb" file (since v1.0.0)

You also can write your own check functions into the `/root/.notifyme/check.rb` file, e.g.

```ruby
# file: /root/.notifyme/check.rb
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

## Add tasks into the "/root/.notifyme/check/" directory (since v1.0.0)

Instead of put all of tasks into the `notifyme_config.rb` file. you can also put them into the `/root/.notifyme/check/` directory, one task one file, it's easy to manage them if you have too many things to check.
e.g.

```ruby
# file: /root/.notifyme/check/redis.rb

def check_redis(t)
  t.sleep_time = 5
  t.command = lambda { check :tcp, :host => 'localhost', :port => 6379 }
end
```

## Nagios plugin

You can download it from http://www.nagios.org/download/plugins/ and install it into the "/usr/local/nagios/libexec" directory for example.
Then, NotifyMe can work with the plugin like:

```ruby
# file: /root/.notifyme/check/ssh.rb

def check_ssh(t)
  t.sleep_time = 60
  t.command = lambda { nagios_check :ssh, "localhost" }
end
```

The above check task will invoke the "/usr/local/nagios/libexec/check_ssh localhost" command. 

If the plugin is not installed in the "/usr/local/nagios/libexec" directory, you need to set it manually in the "/root/.notifyme/notifyme_config.rb" file:

```ruby
# file: /root/.notifyme/notifyme_config.rb

NotifyMe::Start.config do
# ...
  nagios_directory "/usr/lib/nagios/plugins"
# ...
end

```

## Output

The output from every task's command will be processed (send to endpoints such as email, console etc.) only if the output is not empty, otherwise do nothing.

## Version

v 1.1.3

## TODO

Add some SPECS
