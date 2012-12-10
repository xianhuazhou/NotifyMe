module NotifyMe

  VERSION = '1.0.1'

  autoload :Task, 'notifyme/task'
  autoload :Log, 'notifyme/log'
  autoload :Check, 'notifyme/check'

  class Start
    class << self

      # log 
      @@log_args = [:stdout]
      @@log_format = :text

      # tasks list
      @@tasks = []

      def run!
        puts 'NotifyMe v' + NotifyMe::VERSION
        load_custom_check_functions
        start = new(ARGV[0])
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
        File.join(ENV['HOME'], ".notifyme")
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

      def log(*args)
        @@log_args = args
      end

      def log_format(format)
        @@log_format = format
      end

      def log_directory(directory)
        $stderr.puts "Warn: the \"log_direcotry\" has been deprecated. You can find the error messages in the /var/log/ directory."
      end
    end

    def run
      tasks_thread = []
      @mutex = Mutex.new
      @@tasks.each do |task|
        tasks_thread << Thread.new(task) do
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
        log_error task.name, task.command, e.to_s
        task.result = e.to_s
      end

      # works fine.
      return if task.result.to_s.empty?

      # restart the command if need
      begin
        task.restart_command.call if task.restart_command
      rescue Exception => e
        log_error task.name, task.restart_command, e.to_s
      end

      @mutex.synchronize do 
        begin
          task.logger << task
        rescue Exception =>  e
          puts e.backtrace.join("\n")
        end
      end
    end

    def log_error(task_name, command, msg)
      Syslog.log Syslog::LOG_ERR, "[#{Time.new.to_s}] #{task_name} # #{command} : #{msg}"
    end

    def initialize(config_file)
      require config_file
    end
  end
end
