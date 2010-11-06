module NotifyMe
  class Task
    attr_accessor :name, :sleep_time, :start_run_time, :end_run_time,
      :logger, :command, :result,
      :log_format

    def command=(cmd)
      return if cmd.nil?

      unless cmd.is_a?(Proc)
        cmd = cmd.new if cmd.class.is_a?(Class)
      end

      if cmd.respond_to? :call
        @command = cmd
        return
      end

      raise 'Invalid command parameter'
    end
  end
end
