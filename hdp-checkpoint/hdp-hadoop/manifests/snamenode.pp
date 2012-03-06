class hdp-hadoop::snamenode(
  $service_state = 'running',
  $opts = {}
)  
{
  include hdp-hadoop::params
  $dfs_name_dir = $hdp-hadoop::params::dfs_name_dir
  
  $hdp::params::service_exists['hdp-hadoop::snamenode'] = true
 
  include hdp-hadoop  #adds package, users, directories, and common configs
  Hdp-hadoop::Package<||>{include_64_bit => true}

  Hdp-Hadoop::Configfile<||>{snamenode_host => $hdp::params::host_address}
  
  hdp-hadoop::snamenode::create_name_dirs { $dfs_name_dir: }
  
  hdp-hadoop::service{ 'secondarynamenode':
    ensure       => $service_state,
    user         => $hdp-hadoop::params::hdfs_user,
    initial_wait => $opts[wait]
  }
  #top level does not need anchors
  Class['hdp-hadoop'] -> Hdp-hadoop::Service['secondarynamenode']
  Hdp-hadoop::Namenode::Create_name_dirs<||> -> Hdp-hadoop::Service['secondarynamenode']
}

define hdp-hadoop::snamenode::create_name_dirs()
{
  $dirs = hdp_array_from_comma_list($name)
  hdp::directory_recursive_create { $dirs :
    owner => $hdp-hadoop::params::hdfs_user,
    mode => '0755'
  }
}
