class hdp-hadoop::datanode(
  $service_state = running,
  $opts = {}
) 
{
  include hdp-hadoop::params
  $dfs_data_dir = $hdp-hadoop::params::dfs_data_dir
  
  $hdp::params::service_exists['hdp-hadoop::datanode'] = true
 
  include hdp-hadoop #adds package, users, directories, and common configs
  Hdp-hadoop::Package<||>{include_32_bit => true}
  Hdp-hadoop::Configfile<||>{size => 32}

  hdp-hadoop::datanode::create_data_dirs { $dfs_data_dir: }
  
  hdp-hadoop::service{ 'datanode':
    ensure       => $service_state,
    user         => $hdp-hadoop::params::hdfs_user,
    initial_wait => $opts[wait]
  }
  #top level does not need anchors
  Class['hdp-hadoop'] -> Hdp-hadoop::Service['datanode']
  Hdp-hadoop::Datanode::Create_data_dirs<||> -> Hdp-hadoop::Service['datanode']
}

define hdp-hadoop::datanode::create_data_dirs()
{
  $dirs = hdp_array_from_comma_list($name)    
  hdp::directory_recursive_create { $dirs :
    owner => $hdp-hadoop::params::hdfs_user,
    mode => '0750'
  }
}
