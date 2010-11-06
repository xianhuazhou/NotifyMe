module NotifyMe
  class Task
    attr_accessor :name, :sleep_time, :start_run_time, :end_run_time,
      :logger, :command, :restart_command, :result,
      :log_format

    def restart_command=(cmd)
      @restart_command = get_command(cmd)
    end

    def command=(cmd)
      @command = get_command(cmd)
    end

    private
    def get_command(cmd)
      return if cmd.nil?

      unless cmd.is_a? Proc
        cmd = cmd.new if cmd.class.is_a?(Class)
      end

      return cmd if cmd.respond_to? :call

      raise 'Invalid command parameter'
    end
  end
end
