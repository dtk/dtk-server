class hdp-hadoop::namenode(
  $service_state = 'running',
  $slave_hosts = [],
  $snamenode_hosts = [$hdp::params::host_address], #TODO: fix; to be single host
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
) inherits hdp-hadoop::params
{
  #adds package, users and directories, and common hadoop configs
  #hdp-hadoop::common { 'hadoop': 
  #  namenode => true
  #}
  class { 'hdp-hadoop' : }
   
  Hdp-Hadoop::Configfile<||>{namenode_host => $hdp::params::host_address}
  Hdp::Configfile<||>{namenode_host => $hdp::params::host_address} #for components other than hadoop (e.g., hbase) 
  
  class {'hdp-hadoop::namenode::format' : }

  hdp-hadoop::service{ 'namenode':
    enable       => $service_state,
    user         => $hdp-hadoop::params::hdfs_user,
    initial_wait => $opts[wait]
  }
  #top level does not need anchors
  #Hdp-hadoop::Common['hadoop'] -> Class['hdp-hadoop::namenode::format'] -> Hdp-hadoop::Service['namenode']
  Class['hdp-hadoop'] -> Class['hdp-hadoop::namenode::format'] -> Hdp-hadoop::Service['namenode']
}

