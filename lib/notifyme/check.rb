module NotifyMe
  class Check
    class << self
      def process(args = {})
        if %x{ps aux | grep #{args[:name]} | grep -v grep}.strip == ''
          raise "Process #{args[:name]} is not running!"
        end
      end

      def tcp(args = {})
        require 'socket'
        TCPSocket.new(args[:host] || 'localhost', args[:port])
      end

      def http(args = {})
        require 'http_request'
        url = args[:url]
        hr = HttpRequest.get(url)
        if args[:include]
          raise "The page #{url} doesn't include \"#{args[:include]}\"." unless hr.body.include?(args[:include])
        else
          raise "Can't open #{url}." unless hr.code_200?
        end
      end
    end
  end
end
