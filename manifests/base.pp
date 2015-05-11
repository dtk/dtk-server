class dtk_user::base(
) inherits dtk_user::params
{

  file { $sudo_config_dir:
    ensure => 'directory'
  }

  $sudo_base_cmd = "echo '#includedir ${sudo_config_dir}' >> ${sudo_config_file}"
  $sudo_cmd = "chmod 640 ${sudo_config_file}; ${sudo_base_cmd}; chmod 440 ${sudo_config_file}"
  $sudo_unless =  "grep '#includedir' ${sudo_config_file} | grep ${sudo_config_dir}"

  exec { 'update sudoers':
    command => $sudo_cmd,
    unless  => $sudo_unless,
    path    => ['/bin'],
    require => File[$sudo_config_dir]
  }
}

