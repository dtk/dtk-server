class hdp-hadoop::snamenode(
  $service_state = 'running',
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
)  
{
  include hdp-hadoop  #adds package, users, directories, and common configs

  Hdp-Hadoop::Configfile<||>{snamenode_host => $hdp::params::host_address}
  
  hdp-hadoop::service{ 'secondarynamenode':
    enable       => $service_state,
    user         => $hdp-hadoop::params::hdfs_user,
    initial_wait => $opts[wait]
  }
  #top level does not need anchors
  Class['hdp-hadoop'] -> Hdp-hadoop::Service['secondarynamenode']
}

