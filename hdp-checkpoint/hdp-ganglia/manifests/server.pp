class hdp-ganglia::server(
  $service_state = running,
  $monitored_hosts = undef,
  $opts = {}
)
{
  include hdp-ganglia::params

  class { 'hdp-ganglia::server::packages': }

  class { 'hdp-ganglia::config': ganglia_server_host => $hdp::params::host_address }

  hdp-ganglia::config::generate { ['HDPHBaseMaster','HDPJobTracker','HDPNameNode','HDPSlaves']:
    ganglia_service => 'gmond',
    role => 'server'
  }
  hdp-ganglia::config::generate { 'gmetad':
    ganglia_service => 'gmetad',
    role => 'server'
  }


  #top level does not need anchors
  Class['hdp-ganglia::server::packages'] -> Class['hdp-ganglia::config'] -> Hdp-ganglia::Config::Generate<||>
}

class hdp-ganglia::server::packages()
{
  hdp::package { ['ganglia-monitor','ganglia-server','ganglia-gweb','ganglia-hdp-gweb-addons'] : provider => 'yum'}
}