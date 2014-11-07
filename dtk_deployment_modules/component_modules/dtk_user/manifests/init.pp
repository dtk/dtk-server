class dtk_user(){}

define dtk_user::add_sudo_access()
{
  include dtk_user::params
  $username = $name
  $sudo_config_dir = $dtk_user::params::sudo_config_dir

  file { "${sudo_config_dir}/${username}":
    ensure  => 'present',
    content => "${username}  ALL=(ALL) NOPASSWD:ALL",
    mode    => '0440'
  }
}
