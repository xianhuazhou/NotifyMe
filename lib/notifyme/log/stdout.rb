module NotifyMe
    module Log
        class Stdout < Logger
            def <<(task)
                puts generate(task)
                puts
            end
        end
    end
end
