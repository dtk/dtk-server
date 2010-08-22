#require File.expand_path('user_specific.rb',  File.dirname(__FILE__))

require File.expand_path('environment_config.rb',  File.dirname(__FILE__))

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
R8::Config[:default_layout] = "default"

#Application paths.., these should be set/written by templating engine on every call
#R8::Config[:base_uri] = "http://172.22.101.112:7000"
R8::Config[:base_uri] = R8::EnvironmentConfig::Base_Uri
R8::Config[:base_js_uri] = R8::Config[:base_uri] + "/js"
R8::Config[:base_css_uri] = R8::Config[:base_uri] + "/css"
R8::Config[:base_images_uri] = R8::Config[:base_uri] + "/images"


#Database related config params
R8::Config[:database] = Hash.new
R8::Config[:database][:hostname] = "127.0.0.1"
R8::Config[:database][:user] = "postgres"
R8::Config[:database][:pass] = "bosco"
R8::Config[:database][:name] = "db_main"
R8::Config[:database][:type] = "postgres"


#these are used in template.r8.rb and view.r8.rb
#R8::Config[:sys_root_path] = "C:/webroot/R8Server"

#TODO: eventually cleanup to be more consise of use between root, path,dir, etc
R8::Config[:sys_root_path] = R8::EnvironmentConfig::System_Root_Dir
R8::Config[:app_root_path] = "#{R8::Config[:sys_root_path]}/#{R8::Config[:application_name]}"
R8::Config[:app_cache_root] = "#{R8::Config[:sys_root_path]}/cache/#{R8::Config[:application_name]}"
R8::Config[:system_views_root] = "#{R8::Config[:sys_root_path]}/system/view"
R8::Config[:meta_templates_root] = "#{R8::Config[:app_root_path]}/meta"
R8::Config[:i18n_root] = "#{R8::Config[:app_root_path]}/i18n"
R8::Config[:dev_mode] = true

R8::Config[:js_file_dir] = "#{R8::Config[:app_root_path]}/public/js"
R8::Config[:css_file_dir] = "#{R8::Config[:app_root_path]}/public/css"

R8::Config[:js_file_write_path] = "#{R8::Config[:app_root_path]}/public/js"
R8::Config[:js_templating_on] = false

