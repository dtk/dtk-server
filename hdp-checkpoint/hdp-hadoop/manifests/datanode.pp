class hdp-hadoop::datanode(
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
) 
{
 
  include hdp-hadoop #adds package, users, directories, and common configs
  
  hdp-hadoop::datanode::configfile { 'hdfs-site.xml':}
  
  hdp-hadoop::service{ 'datanode':
    user         => $hdp-hadoop::params::hdfs_user,
    initial_wait => $opts[wait]
  }
  #top level does not need anchors
  Class['hdp-hadoop'] ->  Hdp-hadoop::Datanode::Configfile<||> -> Hdp-hadoop::Service['datanode']
}

define hdp-hadoop::datanode::configfile()
{
  hdp-hadoop::configfile { $name: 
    owner => $hdp-hadoop::params::hdfs_user
  }
}