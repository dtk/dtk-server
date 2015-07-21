class dtk_postgresql::server
(
  $max_connections = $dtk_postgresql::params::max_connections,
  $ssl = $dtk_postgresql::params::ssl
) inherits dtk_postgresql::params
{
  #include dtk_postgresql::params
  $version = $dtk_postgresql::params::version
  $server_package = $dtk_postgresql::params::server_package
  $server_user = $dtk_postgresql::params::server_user
  $server_conf_dir = $dtk_postgresql::params::server_conf_dir 
  $server_data_dir = $dtk_postgresql::params::server_data_dir	
  $external_pid_file = $dtk_postgresql::params::external_pid_file
  #$ssl = $dtk_postgresql::params::ssl
  $unix_socket_directory = $dtk_postgresql::params::unix_socket_directory
  $postgresql_conf = "${server_conf_dir}/postgresql.conf"  
  $pg_hba_conf = "${server_conf_dir}/pg_hba.conf"  

  package { $server_package: }

  file { $postgresql_conf:
    content => template("dtk_postgresql/postgresql-${version}.conf.erb"),
    owner   => $server_user,
    group   => $server_user,
    require => Package[$server_package]
  }  

  file { $pg_hba_conf: 
    content => template('dtk_postgresql/pg_hba.conf.erb'),
    owner   => $server_user,
    group   => $server_user,
    require => Package[$server_package]
  }  

#  file { '/var/run/postgresql':
#    ensure  => 'directory',
#    owner   => $server_user,
#    group   => $server_user,
#    before  => Package[$server_package]
#  }

  sysctl { 'kernel.shmmax': 
    value => 41943040
  }

  if $::osfamily == 'RedHat' {
    exec { 'postgresql initdb':
      command => '/sbin/service postgresql initdb',
      before  => [ Service['postgresql'], File[ $pg_hba_conf, $postgresql_conf ] ],
      creates => '/var/lib/pgsql/data/pg_log/'
    }
  }

  service { 'postgresql':
    enable    => true,
    ensure    => true,
    subscribe => [File[$postgresql_conf],File[$pg_hba_conf]],
    require   => Sysctl['kernel.shmmax'],
  }
}
