module NotifyMe
  class Check
    class << self
      def process(args = {})
        unless %x{ps -e}.include? args.name
          raise "Process #{args.name} is not running!"
        end
      end

      def tcp(args = {})
        require 'socket'
        TCPSocket.new(args[:host], args[:port])
      end
    end
  end
end
