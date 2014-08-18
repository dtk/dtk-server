#TODO: want internal links to connect these with gitolite params
class dtk_server::params()
{

  $config_base = '/etc/dtk'
  $default_port = 7000
  $app_repos = ['server','common']
  $app_packages = ['libxslt1-dev','libsexp-processor-ruby','libpq-dev'] 
  
#  $app_gems_pre = ['sexp_processor']
#  $app_gems = ['ramaze','sequel','active_support','ruote','fog','eventmachine', 'pg','rspec','sshkey','ruby-debug'] 
#  $app_gem_versions = {
#    sequel => '3.25.0'  
#  }
  $non_bundler_gems = {
   #TODO: because bundler cannot build this; needs compilation
   'json' => {
     provider => 'gem',
     ensure   => '1.5.2'
   }
  }
  $repo_urls = {
    'server' => 'git@github.com:rich-reactor8/server.git',
    'common' => 'git@github.com:rich-reactor8/dtk-common.git',
  }
  $repo_targets = {
    'server' => 'server',
    'common' => 'dtk-common'
  }

  $repo_hostnames = ['github.com']

  $mcollective_plugins_dir = '/usr/share/mcollective/plugins' #hard coded in dtk server code

  $sudo_config_file = '/etc/sudoers'
  $sudo_config_dir = '/etc/sudoers.d/'

}
