class hdp-dashboard(
  $service_state = running,
  $opts = {}
)
{
  include hdp-dashboard::params
  
  $conf_dir =  $hdp-dashboard::params::conf_dir
  
  class { 'hdp-dashboard::packages': }
  
  hdp::directory_recursive_create { $conf_dir: }
 
  hdp-dashboard::configfile { 'cluster_configuration.json' : }
  Hdp-Dashboard::Configfile<||>{dashboard_host => $hdp::params::host_address}
  
  class { 'hdp-dashboard::service' : ensure => $service_state}
  
  #top level does not need anchors
  Class['hdp-dashboard::packages'] -> Hdp::Directory_recursive_create[$conf_dir] ->
   Hdp-Dashboard::Configfile<||> -> Class['hdp-dashboard::service']
}

class hdp-dashboard::packages()
{
  hdp::package { 'dashboard': 
    provider => 'yum'
  } 
  
  package { 'php-pecl-json': } 
}

###config file helper
define hdp-dashboard::configfile(
  $dashboard_host = undef
)
{
  
  hdp::configfile { $name:
    component      => 'dashboard',
    owner          => root,
    group          => root,
    conf_dir       => $hdp-dashboard::params::conf_dir,
    dashboard_host => $dashboard_host
  }
}


class hdp-dashboard::service($ensure)
{
  service { 'httpd': ensure => $ensure} 
}
