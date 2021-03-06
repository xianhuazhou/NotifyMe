module NotifyMe

  VERSION = '1.1.5'
  DEFAULT_CONFIG_FILE = "/root/.notifyme/notifyme_config.rb"

  autoload :Task, 'notifyme/task'
  autoload :Log, 'notifyme/log'
  autoload :Check, 'notifyme/check'

  class Start
    class << self

      # log 
      @@log_args = [:stdout]
      @@log_format = :text

      # nagios
      @@nagios_directory = "/usr/local/nagios/libexec"

      # tasks list
      @@tasks = []

      def run!
        puts 'NotifyMe v' + VERSION
        @@config_file = ARGV[0] || DEFAULT_CONFIG_FILE 
        load_custom_check_functions
        start = new(@@config_file)
        load_custom_check_tasks
        start.run
      end

      def load_custom_check_functions
        file = File.join(custom_notifyme_dir, "check.rb")
        if File.exists? file
          load file
          puts "Loaded custom check functions from #{file}."
        end
      end

      def load_custom_check_tasks
        task_files = File.join(custom_notifyme_dir, 'check', '*.rb')
        Dir[task_files].each do |task_file|
          load task_file
          task_name = File.basename(task_file.sub('.rb', ''))
          task_func = "check_#{task_name}"
          if defined? task_func
            task task_func do |t|
              method(task_func).call t
            end
          end
        end
      end

      def custom_notifyme_dir
        notifyme_dir = File.join(ENV['HOME'], ".notifyme")
        return notifyme_dir if File.directory?(notifyme_dir)

        setup notifyme_dir
      end

      def setup(notifyme_dir)
        FileUtils.mkdir_p notifyme_dir
        FileUtils.mkdir_p File.join(notifyme_dir, 'check')

        if @@config_file == DEFAULT_CONFIG_FILE 
          default_config_file = File.expand_path(File.dirname(__FILE__) + '/../../notifyme_config.rb')
          basic_config = File.read(default_config_file).split('# add some tasks').first
          File.open("#{notifyme_dir}/notifyme_config.rb", "w") do |f|
            f.write basic_config + "\nend"
          end
        end

        File.open("#{notifyme_dir}/check.rb", "w") do |f|
          f.write <<-EOF
class NotifyMe::Check
  class << self
    # def something(args = {}) 
    #  return "Something went wrong of your system" if not true 
    # end 
  end 
end
          EOF
        end

        File.open("#{notifyme_dir}/check/mytask.rb", "w") do |f|
          f.write <<-EOF
def check_mytask(t)
  # t.sleep_time = 5
  # t.command = lambda { check :something }
  # t.restart_command = lambda { `/etc/init.d/something restart` }
end
          EOF
        end

        notifyme_dir
      end

      def config(&block)
        class_eval &block
      end

      private

      def task(name)
        raise 'Invalid task calls' unless block_given?
        puts "Added task #{name}"
        task = NotifyMe::Task.new
        task.name = name
        task.logger ||= NotifyMe::Log::Base.new(@@log_args).logger
        task.log_format ||= @@log_format
        yield task
        @@tasks << task
      end

      def check(name, args = {})
        begin
          NotifyMe::Check.method(name).call args
          nil
        rescue Exception => e
          "Check #{name} failed: #{e}"
        end
      end

      def nagios_check(name, args = '')
        cmd = "#{@@nagios_directory}/check_#{name} #{args}"
        begin
          result = `#{cmd}`
          if $?.to_i == 0
            nil
          else
            "#{result.strip} (nagios check)"
          end
        rescue Exception => e
          "Nagios check_#{name} failed: #{e}"
        end
      end

      def log(*args)
        @@log_args = args
      end

      def log_format(format)
        @@log_format = format
      end

      def nagios_directory(directory)
        @@nagios_directory = directory
      end

      def log_directory(directory)
        $stderr.puts "Warn: the \"log_direcotry\" has been deprecated. You can find the error messages in the /var/log/syslog file."
      end
    end

    def run
      tasks_thread = []
      @mutex = Mutex.new
      @@tasks.each do |task|
        tasks_thread << Thread.new(task) do
          next if task.name.nil? || task.sleep_time.nil?
          loop do
            Thread.current[:name] = task.name
            sleep task.sleep_time
            run_task(task) if task.command.respond_to? :call
          end
        end
      end

      tasks_thread.each do |t| t.join end
    end

    private

    def run_task(task)
      begin
        task.start_run_time = Time.now.to_i
        task.result = task.command.call
        task.end_run_time = Time.now.to_i
      rescue Exception => e
        task.result = e.to_s
      end

      # the task works fine.
      if task.result.to_s.empty?
        task.logger.clean_log_history! task
        return
      end

      # restart the command if needed
      begin
        task.restart_command.call if task.restart_command
      rescue Exception => e
        syslog_error task.name, task.restart_command, e.to_s
      end

      @mutex.synchronize do 
        begin
          if task.logger.can_log? task
            task.logger << task
            task.logger.add_log_history task
            syslog_error task.name, "!", task.result.to_s
          end
        rescue Exception => e
          syslog_error task.name, "save_error_log", e.to_s + "\n" + e.backtrace.join("\n")
        end
      end
    end

    def syslog_error(task_name, command, msg)
      Syslog.close if Syslog.opened?
      Syslog.open 'notifyme', Syslog::LOG_NDELAY, Syslog::LOG_USER
      Syslog.log Syslog::LOG_ERR, "[#{Time.new.to_s}] #{task_name} # #{command} : #{msg}"
      Syslog.close
    end

    def initialize(config_file)
      require config_file
    end
  end
end
