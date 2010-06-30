
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



#need to rework/architect as needed, this is from first test pass

module R8
  Config = Hash.new
end

#Application defaults
R8::Config[:application_name] = "application"
R8::Config[:default_language] = "en.us"
R8::Config[:default_template] = "default.template.erubis"

#Application paths.., these should be set/written by templating engine on every call
#R8::Config[:base_uri] = "http://172.22.101.112:7000"
R8::Config[:base_uri] = "http://localhost:7000"
R8::Config[:public_js_root] = R8::Config[:base_uri] + "/js"
R8::Config[:public_css_root] = R8::Config[:base_uri] + "/css"
R8::Config[:public_images_root] = R8::Config[:base_uri] + "/images"


#Database related config params
R8::Config[:database] = Hash.new
R8::Config[:database][:hostname] = "127.0.0.1"
R8::Config[:database][:user] = "postgres"
R8::Config[:database][:pass] = "bosco"
R8::Config[:database][:name] = "db_main"
R8::Config[:database][:type] = "postgres"


#these are used in view.r8.rb
R8::Config[:sys_root_path] = "/root/R8Server"
R8::Config[:app_root_path] = "/root/R8Server"
R8::Config[:app_cache_root] = "/root/R8Server/cache/"+R8::Config[:application_name]
R8::Config[:core_view_root] = R8::Config[:sys_root_path] + "/system/core/view"
#R8::Config[:devMode] = false
R8::Config[:devMode] = true

#these are used in template.r8.rb
R8::Config[:js_file_write_path] = "/root/R8Server/application/public/js"
R8::Config[:js_templating_on] = true

