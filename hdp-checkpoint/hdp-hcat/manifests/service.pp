class hdp-hcat::service(
  $enable = undef,
  $ensure = undef,
  $initial_wait = undef
)
{
  include $hdp-hcat::params
  $user = $hdp-hcat::params::hcat_user
  $conf_dir = $hdp-hcat::params::conf_dir
  $cmd = "/bin/env ZOOCFGDIR=${conf_dir} ZOOCFG=zoo.cfg /usr/sbin/hcatServer.sh"
  $pid_file = $hdp-hcat::params::hcat_pid_file  

  if ($enable == 'running') {
    $daemon_cmd = "su - ${user} -c  '${cmd} start'"
    $no_op_test = "ls ${pid_file} >/dev/null 2>&1 && ps `cat ${pid_file}` >/dev/null 2>&1"
  } else {
    $daemon_cmd = "su - ${user} -c  '${cmd} stop'"
    $no_op_test = undef
  }

  hdp-hcat::service::directory { $hdp-hcat::params::hcat_pid_dir : }
  hdp-hcat::service::directory { $hdp-hcat::params::hcat_log_dir : }
  
if (true == false) {
  hdp::exec { $daemon_cmd:
    command => $daemon_cmd,
    unless  => $no_op_test,
    initial_wait => $initial_wait
  }
 
  anchor{'hdp-hcat::service::begin':} -> Hdp-hcat::Service::Directory<||> -> Hdp::Exec[$daemon_cmd] -> anchor{'hdp-hcat::service::end':}
} else {
  anchor{'hdp-hcat::service::begin':} -> Hdp-hcat::Service::Directory<||> -> anchor{'hdp-hcat::service::end':}
}
}

define hdp-hcat::service::directory()
{
  hdp::directory_recursive_create { $name: 
    owner => $hdp-hcat::params::hcat_user,
    mode => '0755'
  }
}

