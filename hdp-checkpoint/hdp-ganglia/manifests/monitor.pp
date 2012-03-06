#must be put after monitored components because of use of params::service_exist and component_exists
class hdp-ganglia::monitor(
  $service_state = running,
  $ganglia_server_host = undef,
  $opts = {}
)
{
  include hdp-ganglia::params
  
  class { 'hdp-ganglia': }
  
  hdp::package { 'ganglia-monitor' : provider => 'yum'}

  class { 'hdp-ganglia::config': ganglia_server_host => $ganglia_server_host}

  if ($hdp::params::component_exists['hdp-hadoop'] == true) {
    class { 'hdp-hadoop::enable-ganglia': }
  }

  class { 'hdp-ganglia::monitor::config-gen': }
  
  class { 'hdp-ganglia::service::gmond': ensure => $service_state}

   #top level does not need anchors
   Class['hdp-ganglia'] -> Hdp::Package['ganglia-monitor'] -> Class['hdp-ganglia::config'] -> 
    Class['hdp-ganglia::monitor::config-gen'] -> Class['hdp-ganglia::service::gmond']
}

class hdp-ganglia::monitor::config-gen()
{

  $service_exists = $hdp::params::service_exists

  if ($service_exists['hdp-hadoop::namenode'] == true) {
    hdp-ganglia::config::generate { 'HDPNameNode':}
  }
  if ($service_exists['hdp-hadoop::jobtracker'] == true){
    hdp-ganglia::config::generate { 'HDPJobTracker':}
  }
  if ($service_exists['hdp-hbase::master'] == true) {
    hdp-ganglia::config::generate { 'HDPHBaseMaster':}
  }
  if ($service_exists['hdp-hadoop::datanode'] == true) {
    hdp-ganglia::config::generate { 'HDPSlaves':}
  }
  Hdp-ganglia::Config::Generate<||>{
    ganglia_service => 'gmond',
    role => 'monitor'
  }
   # 
  anchor{'hdp-ganglia::monitor::config-gen::begin':} -> Hdp-ganglia::Config::Generate<||> -> anchor{'hdp-ganglia::monitor::config-gen::end':}
}