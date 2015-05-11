define common_user($user)
{
  user {$user:
    home       => "/home/${user}",
    shell      => '/bin/bash',
    managehome => true,
    ensure     => present
  }
}

define common_user::common_user_ssh_config($user)
{
  file { "/home/${user}/.ssh":
    ensure => directory,
    mode   => '0700',
    owner  => $user,
    group  => $user,
  }

  file { "/home/${user}/.ssh/config":
    ensure  => 'present',
    mode    => '0644',
    owner   => $user,
    content => template('common_user/ssh/config.erb'),
    require => File["/home/${user}/.ssh"],
  }
}
