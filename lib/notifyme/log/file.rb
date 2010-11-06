module NotifyMe
  module Log
    class File < Logger
      def <<(task)
        file_path = @parameters.is_a?(String) ? 
          @parameters : @parameters[:path]

        ::File.open(file_path, 'a') do |f|
          f.write generate(task)
          f.write "\n"
        end
      end
    end
  end
end
