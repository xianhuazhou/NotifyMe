NotifyMe::Start.config do
  log :stdout

=begin
  log :mail, 
    :host => 'smtp.gmail.com',
    :helo_domain => 'gmail.com',

    :account => 'xxx@gmail.com', 
    :password => '***',

    :from_email => 'from@gmail.com',
    :from_name => 'From Name',

    :to_email => 'to@gmail.com',
    :to_name => 'To Name'

    # or
    :to_email => {'User A' => 'a@gmail.com', 'User B' => 'b@gmail.com'}
    :to_email => ['User A <a@gmail.com>', 'User B<b@gmail.com'] 
=end

  # log :file, '/tmp/test.txt'
  # log :stdout
  # log :mail, :to_email => 'to@email.com'

  # :csv, :text, :xml, :json
  log_format :text

  # set nagios directory
  # nagios_directory "/usr/lib/nagios/plugins"
  #

  ## !! NOTICE: for new installation,
  ## !!         It's not recommended that to put "check tasks" in the notifyme_config.rb file.

  #
  # check disk space usage every 60 seconds, 
  # if one of the disks' space usage > 95%, notification will be sent.
  #
  task :checking_disk_usage do |t|
    t.sleep_time = 60
    t.command = lambda {
      if %x{df -h}.scan(/\s+(\d+)%\s+/).find {|pcent| pcent.first.to_i > 95}
        raise "Warning: at least 1 disk space usage > 95%"
      else
        nil
      end
    }
  end

  task :checking_localhost_http do |t|
    t.sleep_time = 5
    t.command = lambda { check :tcp, :host => 'localhost', :port => 80 }
    t.restart_command = lambda { %x{/etc/init.d/httpd start} }
  end
end
