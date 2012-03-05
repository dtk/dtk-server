class hdp-hadoop::tasktracker(
  $service_state = 'running',
  $opts = {}
) 
{
  include hdp-hadoop::params
  $mapred_local_dir = $hdp-hadoop::params::mapred_local_dir
  
  include hdp-hadoop #adds package, users, directories, and common configs
  Hdp-hadoop::Package<||>{include_32_bit => true}
  Hdp-hadoop::Configfile<||>{size => 32}
  
  hdp-hadoop::tasktracker::create_local_dirs { $mapred_local_dir: }

  hdp-hadoop::service{ 'tasktracker':
    ensure       => $service_state,
    user         => $hdp-hadoop::params::mapred_user,
    initial_wait => $opts[wait]
  }
  
  #top level does not need anchors
  Class['hdp-hadoop'] -> Hdp-hadoop::Service['tasktracker']
  Hdp-hadoop::Tasktracker::Create_local_dirs<||> -> Hdp-hadoop::Service['tasktracker']
}

define hdp-hadoop::tasktracker::create_local_dirs()
{
  $dirs = hdp_array_from_comma_list($name)    
  hdp::directory_recursive_create { $dirs :
    owner => $hdp-hadoop::params::mapred_user,
    mode => '0755'
  }
}