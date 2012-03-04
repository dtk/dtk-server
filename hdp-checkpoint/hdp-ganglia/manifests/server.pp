class hdp-ganglia::server($monitored_hosts = undef) 
{
  include hdp-ganglia::params

  class { 'hdp-ganglia::server::packages': }

  class { 'hdp-ganglia::config': ganglia_server_host => $hdp::params::host_address }

  #top level does not need anchors
  Class['hdp-ganglia::server::packages'] -> Class['hdp-ganglia::config']
}


class hdp-ganglia::server::packages()
{
  hdp::package { ['ganglia-monitor','ganglia-server','ganglia-gweb','ganglia-hdp-gweb-addons'] : provider => 'yum'}
}
