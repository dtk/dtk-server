module XYZ 
  class Config 
    @@configuration = {} unless defined?(@@configuration)
    class << self
      def process_config_file(file_name)
        unless File.exists?(file_name)
          Log("config file #{file_name} does not exist")
          return nil
        end
        instance_eval(IO.read(file_name), file_name, 1)
      end
      def [](x)
        @@configuration[x]
      end
      def get_params()
        @@configuration.keys()
      end
     private
      def method_missing(method_id,*args)
        raise Error.new("wrong number of args") unless args.size == 1
        @@configuration[method_id] = args[0]
      end
    end
  end
end

