define thin(
  $app_dir,
  $daemon_user = $name
)
{
  $daemon_group = $daemon_user
  $daemon_home_dir = "/home/${daemon_user}"
  $server_dir = "${daemon_home_dir}/server/current"
  $thin_dir = "${daemon_home_dir}/thin"
  $thin_conf_dir = "${thin_dir}/conf"
  $thin_config = "${thin_conf_dir}/${daemon_user}.yaml"
  $thin_socket = "${thin_dir}/thin.sock"
  $thin_init_script = "/etc/init.d/thin-${daemon_user}"

  # on ubuntu, we need to start thin with sudo -u $daemon_user
  # this isn't requried on centos
  case $::osfamily {
    'RedHat', 'Linux': {
      # TO-DO: find out if sexp-processor is still required
      $daemon_user_sudo = '' 
    }
    'Debian' : {
      $daemon_user_sudo = "sudo -u ${daemon_user}"
    }
  }

  require thin::package
  #require thin::service

  # Change permissions on daemon user's home directory to allow nginx to connect to the socket
  # because CentOS has more restrictive permissions than Ubuntu
  check_mode { $daemon_home_dir:
    mode => 755,
  }

  file { $thin_config:
    owner   => $daemon_user,
    group   => $daemon_group,
    content => template('thin/server.yml.erb'),
    require => File[$thin_conf_dir]
  } 

  file { $thin_dir:
    ensure => 'directory',
    owner  => $daemon_user
  }

  file { $thin_conf_dir:
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

  file { $thin_init_script:
    content => template('thin/thin.init.erb'),
    mode    => 'o+x',
    require => File[$thin_config]
  }

  service { "thin-${daemon_user}":
    ensure  => true,
    enable  => true,
    require => File[$thin_init_script]
  }

  logrotate::rule { "thin-${daemon_user}":
    path         => "${thin_dir}/log/thin.log",
    rotate       => 5,
    rotate_every => 'week',
    compress     => true,
    postrotate   => "/bin/kill -HUP `cat ${thin_dir}/pid/thin.pid`",
  }
}

define check_mode($mode) {
  exec { "/bin/chmod $mode $name":
    unless => "/bin/sh -c '[ $(/usr/bin/stat -c %a $name) == $mode ]'",
  }
}

