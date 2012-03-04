class hdp-hadoop::namenode(
  $service_state = 'running',
  $slave_hosts = [],
  $opts = {}
) 
{
  include  hdp-hadoop::params
  $dfs_name_dir = $hdp-hadoop::params::dfs_name_dir

  #adds package, users and directories, and common hadoop configs
  class { 'hdp-hadoop' : }
  Hdp-hadoop::Package<||>{include_64_bit => true}

  hdp-hadoop::namenode::create_name_dirs { $dfs_name_dir: }
   
  Hdp-Hadoop::Configfile<||>{namenode_host => $hdp::params::host_address}
  Hdp::Configfile<||>{namenode_host => $hdp::params::host_address} #for components other than hadoop (e.g., hbase) 
  
  class {'hdp-hadoop::namenode::format' : }

  hdp-hadoop::service{ 'namenode':
    enable       => $service_state,
    user         => $hdp-hadoop::params::hdfs_user,
    initial_wait => $opts[wait]
  }
  #top level does not need anchors
  Class['hdp-hadoop'] -> Class['hdp-hadoop::namenode::format'] -> Hdp-hadoop::Service['namenode']
  Hdp-hadoop::Namenode::Create_name_dirs<||> -> Class['hdp-hadoop::namenode::format']
}

define hdp-hadoop::namenode::create_name_dirs()
{
  $dirs = hdp_array_from_comma_list($name)
  hdp::directory_recursive_create { $dirs :
    owner => $hdp-hadoop::params::hdfs_user,
    mode => '0755'
  }
}


