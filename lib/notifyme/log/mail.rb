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

                param[:subject] = "NotifyMe report: %s" 
                param[:subject] = param[:subject] % task.name

                param[:from_email] ||= param[:account]
                param[:from_email] ||= default_from_email

                param[:body] = param[:body_header].to_s + 
                    generate(task) +
                    param[:body_footer].to_s

                smtp = Net::SMTP.new(
                    (param[:address] || param[:host]) || default_host, 
                    param[:port] || default_port
                )

                # go go go!
                smtp.start(param[:helo_domain] || default_host, 
                           param[:account], 
                           param[:password], 
                           param[:authtype] || :plain) do |mail|
                    mail.send_message message(param, task), param[:from_email], param[:to_email]
                end
            end

            private
            def message(param, task)
                time = Time.now
                "From: #{param[:from_name] || param[:from_email]} <#{param[:from_email]}>\r\n" \
                << "To: #{param[:to_name] || param[:to_email]} <#{param[:to_email]}>\r\n" \
                << "Subject: #{param[:subject]}\r\n" \
                << "Date: #{time.to_s}\r\n" \
                << "Content-type: text/plain; charset=UTF-8\r\n" \
                << "Message-Id: <notifyme.#{task.name}.#{time.to_i}@example.com>\r\n" \
                << "\r\n" \
                    << param[:body]
            end
        end
    end
end
