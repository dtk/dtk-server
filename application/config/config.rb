
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

R8::Config[:application_name] = "application"
R8::Config[:default_language] = "en.us"
R8::Config[:default_template] = "default.template.erubis"

#Database related config params
R8::Config[:database] = Hash.new
R8::Config[:database][:hostname] = "localhost"
R8::Config[:database][:user] = "postgres"
R8::Config[:database][:pass] = "bosco"
R8::Config[:database][:name] = "db_main"
R8::Config[:database][:type] = "postgres"


#these are used in view.r8.rb
R8::Config[:appRootPath] = "C:/webroot/R8Server/application/"
R8::Config[:tplCacheRoot] = "C:/webroot/R8Server/cache/application/tplcache/"
#R8::Config[:devMode] = false
R8::Config[:devMode] = true

#these are used in template.r8.rb
R8::Config[:js_file_write_path] = "C:/webroot/R8Server/application/public/js"
R8::Config[:rtpl_compile_dir] = R8::Config[:tplCacheRoot] + 'rtplCompile'
R8::Config[:rtpl_cache_dir] = R8::Config[:tplCacheRoot] + 'rtplCache'
R8::Config[:views_root_dir] = R8::Config[:tplCacheRoot] + 'views'
R8::Config[:js_templating_on] = true

