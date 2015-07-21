class dtk_addons::test_scripts_setup(
  $destination_user,
  $source_user,
  $server = "localhost",
  $port = "443",
  $log,
  $database,
  $server_username,
  $server_password = "r8server",
)
{
  $source = "/home/${source_user}/server/current/test"
  $destination = "/home/${destination_user}"

  exec { 'copy_test_scripts':
    command => "cp -r ${source} /home/${destination_user}",
    user    => $destination_user,
    path    => ['/usr/bin','/usr/local/bin','/bin'],
  }

  file { "/home/${destination_user}/test/functional/rspec/config/config.yml":
    ensure  => 'present',
    owner   => $destination_user,
    content => template('dtk_addons/config.yml.erb'),
    require => Exec['copy_test_scripts']
  }
}

