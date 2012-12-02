module NotifyMe
  class Check
    class << self
      def process(args = {})
        unless %x{ps -e}.include? arg
          raise "Process #{arg} is not running!"
        end
      end

      def tcp(args = {})
        require 'socket'
        TCPSocket.new('localhost', 80) 
      end
    end
  end
end
