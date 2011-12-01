require File.expand_path('../require_first',File.dirname(__FILE__))
r8_require('../../utils/internal/log')
r8_require('../../utils/internal/hash_object')

module R8
  Config = XYZ::HashObject.create_with_auto_vivification()
end

r8_require('environment_config')

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

R8::Config[:login][:path] = "/xyz/user/login"
R8::Config[:login][:resgister] = "/xyz/user/register"
#TODO: below is stub
R8::Config[:login][:redirect] = "/xyz/workspace/index"


#Database related config params
R8::Config[:database][:hostname] = "127.0.0.1"
#R8::Config[:database][:hostname] = "ec2-174-129-28-204.compute-1.amazonaws.com"
R8::Config[:database][:user] = "postgres"
R8::Config[:database][:pass] = "bosco"
R8::Config[:database][:name] = "db_main"
R8::Config[:database][:type] = "postgres"

#Workflow related parameters
R8::Config[:workflow][:type] = "ruote"
#R8::Config[:workflow][:type] = "simple"

if defined? R8::EnvironmentConfig::ImportTestBaseDir
  R8::Config[:repo].set?(:base_directory,R8::EnvironmentConfig::ImportTestBaseDir)
else
  R8::Config[:repo].set?(:base_directory,"/root/r8server-repo")
end
R8::Config[:repo].set?(:type,"git")
R8::Config[:repo][:git][:server_type] = "gitolite"

#TODO: temp for testing
R8::Config[:repo][:git][:gitolite][:hostname] = "ec2-107-22-254-226.compute-1.amazonaws.com"
R8::Config[:repo][:base_directory_test] = "/root/r8server-repo-test"
########end test

#R8::Config[:repo][:git][:gitolite][:hostname] = "127.0.0.1"
R8::Config[:repo][:git][:gitolite][:admin_directory] = "/root/r8_gitolite_admin"


#Command and control related parameters
#R8::Config[:command_and_control][:node_config].set?(:type,"mcollective")
R8::Config[:command_and_control][:node_config].set?(:type,"mcollective__mock")

#TODO: put in provisions to have multiple iias providers at same time
R8::Config[:command_and_control][:iaas].set?(:type,"ec2")
R8::Config[:command_and_control][:iaas][:ec2][:default_image_size] = "t1.micro"
#R8::Config[:command_and_control][:iaas].set?(:type,"ec2__mock")

#optional timer plug
#R8::Config[:timer][:type] = "debug_timeout" # "system_timer"

#these are used in template.r8.rb and view.r8.rb
#R8::Config[:sys_root_path] = "C:/webroot/R8Server"

#Link related config params
R8::Config[:links][:default_type] = "fullBezier"
R8::Config[:links][:default_style] = Array.new
R8::Config[:links][:default_style] = [
  {:strokeStyle=>'#25A3FC',:lineWidth=>3,:lineCap=>'round'},
  {:strokeStyle=>'#63E4FF',:lineWidth=>1,:lineCap=>'round'}
]


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

#freeze
R8::Config.freeze
