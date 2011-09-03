NotifyMe::Start.config do
  log :stdout

=begin
  log :mail, 
    :host => 'smtp.gmail.com',
    :helo_domain => 'gmail.com',
    :tls => true,

    :account => 'xxx@gmail.com', 
    :password => '***',

    :from_email => 'from@gmail.com',
    :from_name => 'from name',

    :to_email => 'to@gmail.com',
    :to_name => 'to name'

    # or
    :to_email => {'User a' => 'a@gmail.com', 'User b' => 'b@gmail.com'}
    :to_email => ['User a <a@gmail.com>', 'User b<b@gmail.com'] 
=end

  # log :file, '/tmp/test.txt'
  # log :stdout
  # log :mail, :to_email => 'to@email.com'

  # :csv, :text, :xml, :json
  log_format :json 

  # log_directory '/tmp/notifyme'

  # add some tasks

  #
  # check disk space usage every 60 seconds, 
  # if one of the disks' space usage > 95%, notification will be sent.
  #
  task :checking_disk_usage do |t|
    t.sleep_time = 60 
    t.command = lambda {
      if %x{df -h}.scan(/\s+(\d+)%\s+/).find {|pcent| pcent.first.to_i > 95} 
        "Warnning: at least 1 disk space usage > 95%"
      else
        nil 
      end
    } 
  end

  task :checking_localhost_http do |t|
    t.sleep_time = 5
    t.command = lambda { 
      require 'socket'
      begin
        TCPSocket.new('localhost', 80)
        nil
      rescue Exception => e
        e.to_s
      end
    } 
    t.restart_command = lambda { %x{/etc/init.d/httpd start} }
  end
end
