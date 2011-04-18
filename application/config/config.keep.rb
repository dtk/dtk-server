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
  Config = Hash.new unless defined? ::R8::Config
end

#Application defaults
R8::Config[:application_name] = "application"
R8::Config[:default_language] = "en.us"
R8::Config[:default_layout] = "default"

#Application paths.., these should be set/written by templating engine on every call
#R8::Config[:base_uri] = "http://172.22.101.112:7000"
R8::Config[:base_uri] = R8::EnvironmentConfig::Base_Uri
R8::Config[:base_js_uri] = R8::Config[:base_uri] + "/js"
R8::Config[:base_js_cache_uri] = R8::Config[:base_uri] + "/js/cache"
R8::Config[:base_css_uri] = R8::Config[:base_uri] + "/css"
R8::Config[:base_images_uri] = R8::Config[:base_uri] + "/images"
R8::Config[:node_images_uri] = R8::Config[:base_uri] + "/images/nodeIcons"
R8::Config[:component_images_uri] = R8::Config[:base_uri] + "/images/componentIcons"
R8::Config[:avatar_base_uri] = R8::Config[:base_uri] + "/images/user_avatars"

R8::Config[:login] = Hash.new
R8::Config[:login][:path] = "/xyz/user/login"
R8::Config[:login][:resgister] = "/xyz/user/register"
#TODO: below is stub
R8::Config[:login][:redirect] = "/xyz/workspace/index"


#Database related config params
R8::Config[:database] = Hash.new
R8::Config[:database][:hostname] = "127.0.0.1"
#R8::Config[:database][:hostname] = "ec2-174-129-28-204.compute-1.amazonaws.com"
R8::Config[:database][:user] = "postgres"
R8::Config[:database][:pass] = "bosco"
R8::Config[:database][:name] = "db_main"
R8::Config[:database][:type] = "postgres"

#Workflow related parameters
R8::Config[:workflow] = Hash.new
#R8::Config[:workflow][:type] = "ruote"
R8::Config[:workflow][:type] = "simple"

#Command and control related parameters
R8::Config[:command_and_control] = Hash.new
R8::Config[:command_and_control][:node_config] = Hash.new
R8::Config[:command_and_control][:node_config][:type] = "mcollective"
#R8::Config[:command_and_control][:node_config][:type] = "mcollective__mock"

R8::Config[:command_and_control][:iaas] = Hash.new
#TODO: put in provisions to have multiple iias providers at same time
R8::Config[:command_and_control][:iaas][:type] = "ec2" 
#R8::Config[:command_and_control][:iaas][:type] = "ec2__mock" 

#optional timer plug
#R8::Config[:timer] = Hash.new
#R8::Config[:timer][:type] = "debug_timeout" # "system_timer"

#these are used in template.r8.rb and view.r8.rb
#R8::Config[:sys_root_path] = "C:/webroot/R8Server"

#TODO: eventually cleanup to be more consise of use between root, path,dir, etc
R8::Config[:sys_root_path] = R8::EnvironmentConfig::System_Root_Dir
R8::Config[:app_root_path] = "#{R8::Config[:sys_root_path]}/#{R8::Config[:application_name]}"
R8::Config[:app_cache_root] = "#{R8::Config[:sys_root_path]}/cache/#{R8::Config[:application_name]}"
R8::Config[:system_views_dir] = "#{R8::Config[:sys_root_path]}/system/view"
R8::Config[:meta_templates_root] = "#{R8::Config[:app_root_path]}/meta"
#TODO: probably converge meta_templates references into meta_base and remove
R8::Config[:meta_base_dir] = "#{R8::Config[:app_root_path]}/meta"
R8::Config[:i18n_base_dir] = "#{R8::Config[:app_root_path]}/i18n"
R8::Config[:dev_mode] = true

R8::Config[:base_views_dir] = "#{R8::Config[:app_root_path]}/view"

R8::Config[:js_file_dir] = "#{R8::Config[:app_root_path]}/public/js"
R8::Config[:css_file_dir] = "#{R8::Config[:app_root_path]}/public/css"

R8::Config[:js_file_write_path] = "#{R8::Config[:app_root_path]}/public/js/cache"
R8::Config[:js_templating_on] = false

R8::Config[:editor_file_path] = "#{R8::Config[:app_root_path]}/editor"
R8::Config[:config_file_path] = "#{R8::Config[:app_root_path]}/config_upload"

R8::Config[:page_limit] = 20
