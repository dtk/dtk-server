class hdp-zookeeper::service(
  $ensure = undef,
  $ensure = undef,
  $initial_wait = undef
)
{
  include $hdp-zookeeper::params
  $user = $hdp-zookeeper::params::zk_user
  $conf_dir = $hdp-zookeeper::params::conf_dir
  $cmd = "/bin/env ZOOCFGDIR=${conf_dir} ZOOCFG=zoo.cfg /usr/sbin/zkServer.sh"

  $pid_file = $hdp-zookeeper::params::zk_pid_file  

  if ($ensure == 'running') {
    $daemon_cmd = "su - ${user} -c  '${cmd} start'"
    $no_op_test = "ls ${pid_file} >/dev/null 2>&1 && ps `cat ${pid_file}` >/dev/null 2>&1"
    #TODO: not using below because checks more than whether there is a service started up
    #$no_op_test = "su - ${user} -c  '${cmd} status'"
  } else {
    $daemon_cmd = "su - ${user} -c  '${cmd} stop'"
    #TODO: put in no_op_test for stopped
    $no_op_test = undef
  }

  hdp::directory_recursive_create { $hdp-zookeeper::params::zk_pid_dir: 
    owner        => $user,
    context_tag => 'zk_service'
  }
  hdp::directory_recursive_create { $hdp-zookeeper::params::zk_log_dir: 
    owner        => $user,
    context_tag => 'zk_service'
  }
   hdp::directory_recursive_create { $hdp-zookeeper::params::zk_data_dir: 
    owner        => $user,
    context_tag => 'zk_service'
  }
  
  hdp::exec { $daemon_cmd:
    command => $daemon_cmd,
    unless  => $no_op_test,
    initial_wait => $initial_wait
  }
 
  anchor{'hdp-zookeeper::service::begin':} -> Hdp::Directory_recursive_create<|context_tag == 'zk_service'|> -> Hdp::Exec[$daemon_cmd] -> anchor{'hdp-zookeeper::service::end':}

  #TODO: probably move to smoketest file
  Anchor['hdp-zookeeper::service::begin'] -> class{'hdp-zookeeper::smoketest_setup':} ->  Anchor['hdp-zookeeper::service::end']
}

class hdp-zookeeper::smoketest_setup()
{
  $cmd = "ln -s /usr/libexec/zkEnv.sh /usr/bin/zkEnv.sh"
  $test = "test -e /usr/bin/zkEnv.sh"
   hdp::exec { $cmd :
     command => $cmd,
     unless  => $test
  }
}


