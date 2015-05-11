class dtk_passenger(
  $ruby_path = $dtk_passenger::ruby_path
  ) inherits dtk_passenger::params

{
  #include dtk_passenger::params
  include dtk_passenger::repo
  
  package { $dtk_passenger::params::package_list:
    ensure => installed,
    require => Class["Dtk_passenger::Repo"],
  }

  file { "/etc/nginx/conf.d/passenger.conf":
    content => template("dtk_passenger/passenger.conf.erb"),
    require => Package[$dtk_passenger::params::package_list],
  }
}
