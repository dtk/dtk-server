class hdp-zookeeper(
  $service_state = running,
  $myid = 1
) 
{
 include hdp-zookeeper::params

 $zk_user = $hdp-zookeeper::params::zk_user
 $zk_config_dir = $hdp-zookeeper::params::conf_dir
 
 hdp::package { 'zookeeper':}
 
 hdp::user{ $zk_user:}

 hdp::directory { $zk_config_dir: }

 hdp-zookeeper::configfile { 'zoo.cfg':}
 hdp-zookeeper::configfile { 'zookeeper-env.sh':}
 
 class { 'hdp-zookeeper::set_myid' : myid => $myid}
 
 class { 'hdp-zookeeper::service' : enable => $service_state}

 #top level does not need anchors
 Hdp::Package['zookeeper'] -> Hdp::User[$zk_user] -> Hdp::Directory[$zk_config_dir] -> Hdp-zookeeper::Configfile<||> -> Class['hdp-zookeeper::set_myid'] -> Class['hdp-zookeeper::service']
}

### config files
define hdp-zookeeper::configfile(
  $mode = undef
) 
{
  hdp::configfile { $name:
    component       => 'zookeeper',
    owner           => $hdp-zookeeper::params::zk_user,
    conf_dir        => $hdp-zookeeper::params::conf_dir,
    mode            => $mode
  }
}

class hdp-zookeeper::set_myid($myid)
{
  $create_file = "${hdp-zookeeper::params::zk_data_dir}/myid"
  $cmd = "echo '${myid}' > ${create_file}"
  hdp::exec{ $cmd:
    command => $cmd,
    creates  => $create_file
  }
}

