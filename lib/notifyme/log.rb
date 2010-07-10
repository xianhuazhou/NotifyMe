module NotifyMe
    module Log
        class Base
            @logger = nil
            @parameters = {}

            def initialize(args)
                @logger = args.first.to_s.downcase
                @parameters = args.last
            end

            def logger
                begin
                    require "notifyme/log/#{@logger}.rb"
                rescue Exception => e
                end
                NotifyMe::Log.const_get(@logger.capitalize).new @parameters
            end

            def self.default
                require 'notifyme/log/stdout.rb'
                NotifyMe::Log::Stdout.new 
            end
        end

        class Logger
            def initialize(parameters = {})
                @parameters = parameters
            end

            protected
            def generate(task)
                method("to_#{task.log_format}").call task
            end

            private

            def to_json(task)
                require 'json'
                JSON to_hash(task) 
            end

            def to_xml(task)
                require 'rexml/document'
                xml = REXML::Element.new 'task'
                fields.each do |f|
                    el = REXML::Element.new f.to_s
                    el.text = task.send(f)
                    xml.add_element el
                end
                xml.to_s
            end

            def to_csv(task)
                require 'csv'
                row = []
                fields.each do |f|
                    row << task.send(f)
                end
                CSV.generate_line row
            end

            def to_text(task)
                output = ''
                fields.each do |f|
                    output << "#{f}: #{task.send(f)}\n"
                end
                output << "\n"
            end

            def to_hash(task)
                hash = {}
                fields.each do |f|
                    hash[f] = task.send(f)
                end
                hash
            end

            def fields
                [:name, :sleep_time, :start_run_time, :end_run_time, :result]
            end
        end
    end
end
