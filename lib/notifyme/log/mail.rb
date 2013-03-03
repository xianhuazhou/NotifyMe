module NotifyMe
  module Log
    class Mail < Logger
      def <<(task)
        param = @parameters
        param = {} unless param.is_a?(Hash)

        # some default settings
        default_host = 'localhost'
        smtp_port = param[:port]
        unless smtp_port
          smtp_port = param[:tls] ? 587 : 25
        end
        smtp_host = (param[:address] || param[:host]) || default_host

        default_from_email = 'notifyme@' + smtp_host

        param[:subject] = "NotifyMe report (#{fact(:hostname)} # #{fact(:ipaddress)}): #{task.name}"
        param[:subject] = param[:subject] % 

        param[:from_email] ||= param[:account]
        param[:from_email] ||= default_from_email
        from = if param[:from_name]
                 "#{param[:from_name]} <#{param[:from_email]}>"
               else
                 param[:from_email]
               end

        param[:body] = param[:body_header].to_s + 
          generate(task) +
          param[:body_footer].to_s

        # go go go!
        recipients = if param[:to_email].is_a? Hash
                       param[:to_email].collect{|name, email| "#{name} <#{email}>"}
                     else
                       param[:to_email]
                     end

        mail = ::Mail.new do
          from from
          to recipients
          subject param[:subject]
          body param[:body]
        end

        if param[:host]
          smtp_settings = {
            :address => smtp_host,
            :port => param[:port] || smtp_port,
            :domain => param[:helo_domain] || default_host,
            :user_name => param[:account] || param[:user_name],
            :password => param[:password],
            :authentication => param[:authentication] || :plain,
            :openssl_verify_mode => param[:openssl_verify_mode],
            :enable_starttls_auto => param[:enable_starttls_auto] || true,
            :tls => param[:tls],
            :ssl => param[:ssl]
          }
          mail.delivery_method :smtp, smtp_settings
        else
          mail.delivery_method :sendmail
        end
        mail.deliver
      end
    end
  end
end
