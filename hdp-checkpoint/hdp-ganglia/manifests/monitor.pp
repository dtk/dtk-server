#TODO: see if can get away from using defined?; this must be put after any of these components
class hdp-ganglia::monitor(
  $service_state = running,
  $ganglia_server_host = undef,
  $opts = {}
)
{
  include hdp-ganglia::params
  
  hdp::package { 'ganglia-monitor' : provider => 'yum'}

  class { 'hdp-ganglia::config': ganglia_server_host => $ganglia_server_host}

  if defined('hdp-hadoop') {
    class { 'hdp-hadoop::enable-ganglia': }
  }

  class { 'hdp-ganglia::monitor::config-gen': }
  
  class { 'hdp-ganglia::service::gmond': ensure => $service_state}

   #top level does not need anchors
  Hdp::Package['ganglia-monitor'] -> Class['hdp-ganglia::config'] -> Class['hdp-ganglia::monitor::config-gen'] ->
   Class['hdp-ganglia::service::gmond']
}


class hdp-ganglia::monitor::config-gen()
{

  if defined('hdp-hadoop::namenode') or defined('hdp-hadoop::snamenode') {
    hdp-ganglia::config::generate { 'HDPNameNode':}
  }
  if defined('hdp-hadoop::jobtracker') {
    hdp-ganglia::config::generate { 'HDPJobTracker':}
  }
  if defined('hdp-hbase::master') {
    hdp-ganglia::config::generate { 'HDPHBaseMaster':}
  }
  if defined('hdp-hadoop::datanode') or defined('hdp-hadoop::tasktracker') {
    hdp-ganglia::config::generate { 'HDPSlaves':}
  }
  Hdp-ganglia::Config::Generate<||>{
    ganglia_service => 'gmond',
    role => 'monitor'
  }
   # 
  anchor{'hdp-ganglia::monitor::config-gen::begin':} -> Hdp-ganglia::Config::Generate<||> -> anchor{'hdp-ganglia::monitor::config-gen::end':}
}