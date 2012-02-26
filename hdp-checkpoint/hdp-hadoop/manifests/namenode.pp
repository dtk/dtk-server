class hdp-hadoop::namenode(
  $service_state = 'running',
  $slave_hosts = [],
  $snamenode_hosts = [$hdp::params::host_address], #TODO: fix; to be single host
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
) inherits hdp-hadoop::params
{
  #include hdp-hadoop #adds package, users and directories, and common hadoop configs
  hdp-hadoop::common { 'hadoop': 
    namenode => true
  }
   
  #hdfs specific config files
  hdp-hadoop::namenode::configfile { 'hdfs-site.xml': }
  
  Hdp-Hadoop::Configfile<||>{namenode_host => $hdp::params::host_address}
  Hdp::Configfile<||>{namenode_host => $hdp::params::host_address} #for components other than hadoop (e.g., hbase) 
  
  class {'hdp-hadoop::namenode::format' : }

  hdp-hadoop::service{ 'namenode':
    enable       => $service_state,
    user         => $hdp-hadoop::params::hdfs_user,
    initial_wait => $opts[wait]
  }
  #top level does not need anchors
  Hdp-hadoop::Common['hadoop'] -> Hdp-hadoop::Namenode::Configfile<||> -> Class['hdp-hadoop::namenode::format'] -> Hdp-hadoop::Service['namenode']
}

define hdp-hadoop::namenode::configfile()
{
  hdp-hadoop::configfile { $name: 
    owner => $hdp-hadoop::params::hdfs_user
  }
}