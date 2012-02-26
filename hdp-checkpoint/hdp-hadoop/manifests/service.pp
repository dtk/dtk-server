
define hdp-hadoop::service(
  $enable = undef,
  $ensure = undef,
  $user,
  $initial_wait = undef
)
{

  #NOTE does not work if namenode and datanode are on same host 
  $pid_dir = "${hdp-hadoop::params::hadoop_piddirprefix}/${user}"
  $pid_file = "${pid_dir}/hadoop-${user}-${name}.pid"
  $log_dir = "${hdp-hadoop::params::hadoop_logdirprefix}/${user}"
  
  $cmd = "/usr/sbin/hadoop-daemon.sh --config ${hdp-hadoop::params::config_dir}"
  if ($enable == 'running') {
    $daemon_cmd = "su - ${user} -c  '${cmd} start ${name}'"
    $service_is_up = "ls ${pid_file} >/dev/null 2>&1 && ps `cat ${pid_file}` >/dev/null 2>&1"
  } else {
    $daemon_cmd = "su - ${user} -c  '${cmd} stop ${name}'"
    $service_is_up = undef
  }
 
  hdp::directory_recursive_create { $pid_dir: 
    owner       => $user,
    context_tag => 'hadoop_service',
  }

  hdp::directory_recursive_create { $log_dir: 
    owner       => $user,
    context_tag => 'hadoop_service',
  }
  
  hdp::exec { $daemon_cmd:
    command      => $daemon_cmd,
    unless       => $service_is_up,
    initial_wait => $initial_wait
  }

  anchor{"hdp-hadoop::service::${name}::begin":} -> Hdp::Directory_recursive_create<|title == $pid_dir or title == $log_dir|> -> Hdp::Exec[$daemon_cmd] -> anchor{"hdp-hadoop::service::${name}::end":}

  if ($enable == 'running') {
    #TODO: look at Puppet resource retry and retry_sleep
    #TODO: can make sleep contingent on $name
    $sleep = 5
    $post_check = "sleep ${sleep}; ${service_is_up}"
    hdp::exec { $post_check:
      command => $post_check,
      unless  => ${service_is_up}
    }
    Hdp::Exec[$daemon_cmd] -> Hdp::Exec[$post_check] -> Anchor["hdp-hadoop::service::${name}::end"]
  }  
}

