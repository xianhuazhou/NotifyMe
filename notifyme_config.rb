class MyTask
  def call
    Time.now.to_s
  end
end

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
=end

  # log :file, '/tmp/test.txt'
  # log :stdout
  # log :mail, :to_email => 'to@email.com'

  # :csv, :text, :xml, :json
  log_format :json 

  # log_directory '/tmp/notifyme'

  # add some tasks

  task :checking_disk do |t|
    t.sleep_time = 3
    t.command = Proc.new { %x{df -h} }
  end

  task :checking_http do |t|
    t.sleep_time = 2
    t.command = MyTask
    t.restart_command = Proc.new { %x{dates} }
  end
end
