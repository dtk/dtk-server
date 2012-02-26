class hdp-hadoop::snamenode(
  $service_state = 'running',
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
)  
{
  include hdp-hadoop  #adds package, users, directories, and common configs

  hdp-hadoop::snamenode::configfile { 'hdfs-site.xml':}
  Hdp-Hadoop::Configfile<||>{snamenode_host => '0.0.0.0'}
  
  hdp-hadoop::service{ 'secondarynamenode':
    enable       => $service_state,
    user         => $hdp-hadoop::params::hdfs_user,
    initial_wait => $opts[wait]
  }
  #top level does not need anchors
  Class['hdp-hadoop'] -> Hdp-hadoop::Snamenode::Configfile<||> -> Hdp-hadoop::Service['secondarynamenode']
}

define hdp-hadoop::snamenode::configfile()
{
  hdp-hadoop::configfile { $name: 
    owner => $hdp-hadoop::params::hdfs_user
  }
}
  
