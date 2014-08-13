class dtk_nginx::base(
  $listen_port = $default_listen_port
) inherits dtk_nginx::params
{
  class { 'nginx::package': }

  class { 'nginx::config':
    require => Class['nginx::package'],
  }

}
