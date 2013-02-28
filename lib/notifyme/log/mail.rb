module NotifyMe
  module Log
    class Mail < Logger
      def <<(task)
        require 'vendor/smtp_add_tls_support.rb'

        param = @parameters
        param = {} unless param.is_a?(Hash)

        # some default settings

        default_host = 'localhost'
        if param[:tls]
          default_port = 587
          Net::SMTP.enable_tls
        else
          default_port = 25
          Net::SMTP.disable_tls
        end

        default_from_email = 'notifyme@' + default_host

        param[:subject] = "NotifyMe report (#{fact(:hostname)} # #{fact(:ipaddress)}): #{task.name}"
        param[:subject] = param[:subject] % 

        param[:from_email] ||= param[:account]
        param[:from_email] ||= default_from_email

        param[:body] = param[:body_header].to_s + 
          generate(task) +
          param[:body_footer].to_s

        smtp_host = (param[:address] || param[:host]) || default_host
        smtp = Net::SMTP.new(
          smtp_host, 
          param[:port] || default_port
        )

        # go go go!
        recipients = if param[:to_email].is_a? Hash
                       param[:to_email].values
                     else
                       param[:to_email]
                     end
        smtp.start(param[:helo_domain] || default_host, 
                   param[:account], 
                   param[:password], 
                   param[:authtype] || :plain
                  ) do |mail|
                    mail.send_message message(param, task), param[:from_email], recipients 
                  end
      end

      private
      def message(param, task)
        to = case param[:to_email]
             when Hash
               param[:to_email].collect{|k, v| "#{k} <#{v}>" }.join(', ')
             when Array
               param[:to_email].collect{|v| "#{v.split('@').first} <#{v}>"}.join(", ")
             else
               "#{param[:to_name] || param[:to_email].split('@').first} <#{param[:to_email]}>"
             end

        time = Time.now
        "From: #{param[:from_name] || param[:from_email]} <#{param[:from_email]}>\r\n" \
        << "To: #{to}\r\n" \
        << "Subject: #{param[:subject]}\r\n" \
        << "Date: #{time.strftime '%a, %d %b %Y %H:%M:%S %z'}\r\n" \
        << "Content-type: text/plain; charset=UTF-8\r\n" \
          << "Message-Id: <notifyme.#{task.name}.#{time.to_i}@#{smtp_host}>\r\n" \
        << "\r\n" \
          << param[:body]
      end
    end
  end
end
