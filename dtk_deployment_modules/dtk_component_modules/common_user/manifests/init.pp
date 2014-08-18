define common_user($user)
{
  user {$user:
    home       => "/home/${user}",
    shell      => '/bin/bash',
    managehome => true,
    ensure     => present
  }
}

define common_user_ssh_config($user)
{
  file { "/home/${user}/.ssh/config":
    ensure  => 'present',
    mode    => '0644',
    owner   => $user,
    content => template('common_user/ssh/config.erb')
  }
}
