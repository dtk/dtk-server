define hdp-hbase::service(
  $ensure = undef,
  $ensure = undef,
  $initial_wait = undef
)
{
  include hdp-hbase::params

  $role = $name
  $user = $hdp-hbase::params::hbase_user
  $conf_dir = $hdp-hbase::params::conf_dir
  $cmd = "/usr/bin/hbase-daemon.sh --config ${conf_dir}"
  $pid_dir = $hdp-hbase::params::hbase_pid_dir
  $pid_file = "${pid_dir}/hbase-hbase-${role}.pid"

  if ($ensure == 'running') {
    #TODO: need to make sure that hdfs service is running

    $daemon_cmd = "su - ${user} -c  '${cmd} start ${role}'"
    $no_op_test = "ls ${pid_file} >/dev/null 2>&1 && ps `cat ${pid_file}` >/dev/null 2>&1"
  } else {
    $daemon_cmd = "su - ${user} -c  '${cmd} stop ${role}'"
    $no_op_test = undef
  }

  hdp::directory_recursive_create { $pid_dir: 
    owner        => $user,
    context_tag => 'hbase_service'
  }
  hdp::directory_recursive_create { $hdp-hbase::params::hbase_log_dir: 
    owner        => $user,
    context_tag => 'hbase_service'
  }

  hdp::exec { $daemon_cmd:
    command      => $daemon_cmd,
    unless       => $no_op_test,
    initial_wait => $initial_wait
  }
  anchor{'hdp-hbase::service::begin':} -> Hdp::Directory_recursive_create<|context_tag == 'hbase_service'|> -> Hdp::Exec[$daemon_cmd] -> anchor{'hdp-hbase::service::end':}
}
