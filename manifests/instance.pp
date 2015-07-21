class dtk_thin::instance(
  $app_dir,
  $daemon_user
)
{
  $daemon_home_dir = "/home/${daemon_user}"
  $daemon_group = $daemon_user
  $thin_dir = "${daemon_home_dir}/thin"
  $thin_config = "${thin_dir}/conf/server.yaml"
  $thin_socket = "${thin_dir}/thin.sock"

  file { $thin_dir:
    ensure => 'directory',
    owner  => $daemon_user
  }
  file { "${thin_dir}/conf":
    ensure  => 'directory',
    owner   => $daemon_user,
    require => File[$thin_dir]
  }
  file { "${thin_dir}/log":
    ensure  => 'directory',
    owner   => $daemon_user,
    require => File[$thin_dir]
  }
  file { "${thin_dir}/pid":
    ensure  => 'directory',
    owner   => $daemon_user,
    require => File[$thin_dir]
  }

  file { $thin_config:
    owner   => $daemon_user,
    content => template('dtk_thin/server.yml.erb'),
    require => File["${thin_dir}/conf"]
  } 

  service { $thin_socket:
    ensure    => true,
    start     => "/usr/local/bin/thin start -C ${thin_config}",
    restart   => "/usr/local/bin/thin restart -C ${thin_config}",
    stop      => "/usr/local/bin/thin stop -C ${thin_config}",
    hasstatus => false,
    require   => File[$thin_config,"${thin_dir}/pid","${thin_dir}/log"]
  }

  logrotate::rule { 'thin':
    path         => "${thin_dir}/log/thin.log",
    rotate       => 5,
    rotate_every => 'week',
    compress     => true,
    postrotate   => "/bin/kill -HUP `cat ${thin_dir}/pid/thin.pid`",
  }
}

