module NotifyMe

  VERSION = '0.1'

  autoload :Task, 'notifyme/task'
  autoload :Log, 'notifyme/log'

  class Start
    class << self

      # log 
      @@log_args = nil
      @@log_format = nil

      # tasks list
      @@tasks = []

      def run!
        puts 'NotifyMe v' + NotifyMe::VERSION
        new(ARGV[0]).run
      end

      def config(&block)
        class_eval &block
      end

      private

      def task(name)
        raise 'Invalid task calls' unless block_given?
        task = Task.new
        task.name = name
        task.logger ||= NotifyMe::Log::Base.new(@@log_args).logger
        task.log_format ||= @@log_format
        yield task
        @@tasks << task
      end

      def log(*args)
        @@log_args = args
      end

      def log_format(format)
        @@log_format = format
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
        task.result = e.to_s
      end

      # works fine.
      return if task.result.to_s.empty?

      # restart the command if need
      task.restart_command.call if task.restart_command

      @mutex.synchronize do 
        begin
          task.logger << task
        rescue Exception =>  e
          puts e.backtrace.join("\n")
        end
      end
    end

    def initialize(config_file)
      require config_file
    end
  end
end
