## Introduction

NotifyMe is a monitoring script, it can monitor processes, services etc., and push the results(error messages usually) to different endpoints(stdout, mails, files etc.) with different formats such as xml, json, csv etc. if something went wrong. 

## Features

* Monitoring processes, whenever a process is stopped, it can notify you and restart the stopped process automatically if needed.
* Run programs in every x seconds/minutes/hours as cron jobs.
* Checking tasks as Nagios does (can also work with the nagios plugins).
* Focusing on a single server but can monitoring any external services such as http, ssh etc..

*Notice: you need root permission to play aroung with notifyme*

## Installation

    # gem install notifyme

## Initialize configuration

    # notifyme

    The command will create a "/root/.notifyme" directory and initialize some basic config files.

## Run it

### run in the background

    # notifyme_daemon start

### debug (use Ctrl + C to stop it)

    # notifyme

    or 

    # notifyme_daemon run

### stop

    # notifyme_daemon stop

### restart

    # notifyme_daemon restart

## Configuration

### output log (text format) to console, it's a good start to test and debug.

```ruby
# file: /root/.notifyme/notifyme\_config.rb
NotifyMe::Start.config do
  # output to the console
  log :stdout

  # output format is text
  log_format :text
end
```

### send log via email notification

```ruby
# file: /root/.notifyme/notifyme\_config.rb
NotifyMe::Start.config do
  # send log to a specified email address (e.g. gmail)
  log :mail, 
    :host => 'smtp.gmail.com',
    :helo_domain => 'gmail.com',
    :tls => true,

    :account => 'xxx@gmail.com', 
    :password => '***',

    :from_email => 'from@gmail.com',
    :from_name => 'From Name',

    :to_email => 'to@gmail.com',
    :to_name => 'To Name'

  # or via the default local SMTP server (e.g. postfix)
  # log :mail, :from_email => 'you@email.com', :to_email => 'to@email.com'

  log_format :text
end
```

### append log to a local file

```ruby
# file: /root/.notifyme/notifyme\_config.rb
NotifyMe::Start.config do
  log :file, '/var/log/notifyme.log'
  log_format :text
end
```

### supported log formats: text, json, xml, hash, csv

```ruby
# file: /root/.notifyme/notifyme\_config.rb
NotifyMe::Start.config do
  log :stdout

  # text
  # log_format :text

  # json
  # log_format :json

  # xml
  # log_format :xml

  # hash
  # log_format :hash

  # csv 
  # log_format :csv
end
```

Notice: the "hash" format doesn't work with "log :email".

## Examples

### Check HTTP Server (e.g. Nginx)

```ruby
# file: /root/.notifyme/check/nginx.rb
def check_nginx(t)
  # checking nginx every 5 seconds 
  t.sleep_time = 5 

  # check nginx if running via tcp 
  t.command = lambda { check :tcp, :host => 'localhost', :port => 80 }
  # or check if there is a nginx process running.
  # t.command = lambda { check :process, :name => 'nginx' }

  # if the above checking command failed, then the restart_command will be executed
  t.restart_command = lambda { %x{/etc/init.d/nginx start} }
end 
```

### Check the "cupsd" process (from "ps -e")

```ruby
# file: /root/.notifyme/check/cupsd.rb
def check_cupsd(t)
  t.sleep_time = 5 
  t.command = lambda {
    unless %x{ps -e}.include? " cupsd"
      raise "Warnning: the process cupsd is not running!"
    end 
  }   
  t.restart_command = lambda { `/etc/init.d/cups start` }   
end
```

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
# file: /root/.notifyme/check/mysqlserver.rb
def check_mysqlserver(t)
  t.sleep_time = 5
  t.command = lambda { check :mysql, :host => 'localhost', :username => 'root', :password => 'pa$$' }
  t.restart_command = lambda { `/etc/init.d/mysqld start` }
end
```

Notice: all of tasks are stored in the `/root/.notifyme/check/` directory, one task per ruby file, the function name format is `check\_#{task\_name}`, the task name is same as filename.

## Nagios plugin

Instead of write check functions by yourself, notifyme can work with nagios plugins, there are many good `check\_\*` programs we can use.

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
# file: /root/.notifyme/notifyme\_config.rb

NotifyMe::Start.config do
# ...
  nagios_directory "/usr/lib/nagios/plugins"
# ...
end

```

## Output

The output from every task's command will be processed (send to endpoints such as email, console etc.) only if the output is not empty, otherwise do nothing.

## Start notifyme automatically

If your notifyme_daemon is installed in "/usr/local/bin/notifyme_daemon".
You can put `/usr/local/bin/notifyme\_daemon start` into the `/etc/rc.local` file.

## Version

v 1.1.4

## TODO

Add some SPECS
