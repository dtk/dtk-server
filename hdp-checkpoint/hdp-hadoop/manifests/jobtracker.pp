class hdp-hadoop::jobtracker(
  $service_state = 'running',
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
)
{
    
  include hdp-hadoop::params
  
  $mapred_user = $hdp-hadoop::params::mapred_user
  $mapred_local_dir = $hdp-hadoop::params::mapred_local_dir 

  include hdp-hadoop

  hdp-hadoop::jobtracker::create_local_dirs { $mapred_local_dir: }
 
  Hdp-Hadoop::Configfile<||>{jtnode_host => $hdp::params::host_address}

  class { 'hdp-hadoop::jobtracker::hdfs-directory' : }
  
  hdp-hadoop::service{ 'jobtracker':
    enable       => $service_state,
    user         => $mapred_user,
    initial_wait => $opts[wait]
  }
  
  hdp-hadoop::service{ 'historyserver':
    enable         => $service_state,
    user           => $mapred_user,
    initial_wait   => $opts[wait],
    create_pid_dir => false,
    create_log_dir => false
  }

  #top level does not need anchors
  Class['hdp-hadoop'] -> Hdp-hadoop::Service['jobtracker'] -> Hdp-hadoop::Service['historyserver']
  Class['hdp-hadoop::jobtracker::hdfs-directory'] -> Hdp-hadoop::Service['jobtracker']
  Hdp-hadoop::Jobtracker::Create_local_dirs<||> -> Hdp-hadoop::Service['jobtracker']
}

define hdp-hadoop::jobtracker::create_local_dirs()
{
  $dirs = hdp_array_from_comma_list($name)    
  hdp::directory_recursive_create { $dirs :
    owner => $hdp-hadoop::params::mapred_user,
    mode => '0755'
  }
}

class hdp-hadoop::jobtracker::hdfs-directory()
{
  #TODO: need to make sure that hdfs service is running
  hdp-hadoop::hdfs::directory{ '/mapred' :
    owner => $hdp-hadoop::params::mapred_user
  }  
   hdp-hadoop::hdfs::directory{ '/mapred/system' :
    owner => $hdp-hadoop::params::mapred_user
  }  
  Hdp-hadoop::Hdfs::Directory['/mapred'] -> Hdp-hadoop::Hdfs::Directory['/mapred/system'] 
}

