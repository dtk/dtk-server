define dtk_client::install(
  $gem_source,
  $username,
  $password,
  $server_host = "dtk16.dtk.io",
  $server_port = "7000",
  $secure_connection_server_port = "443",
  $secure_connection = "test",
  $git_config_user_name = "test",
  $git_config_user_email = "test@reactor8.com"
)
{
  $dtk_client_unix_user = $title
  $ssh_path = "/home/${dtk_client_unix_user}/.ssh/id_rsa"

  file { "/home/${dtk_client_unix_user}/dtk":
    ensure => 'directory',
    owner  => $dtk_client_unix_user,
    group  => $dtk_client_unix_user,
    mode   => 775
  }
  
  file { "/home/${dtk_client_unix_user}/dtk/.connection":
    ensure => 'present',
    owner  => $dtk_client_unix_user,
    content => template('dtk_client/connection.erb')
  }

  file { "/home/${dtk_client_unix_user}/dtk/client.conf":
    ensure => 'present',
    owner  => $dtk_client_unix_user,
    content => template('dtk_client/client.conf.erb')
  }
 
  file { "/home/${dtk_client_unix_user}/.ssh":
    ensure => 'directory',
    owner  => $dtk_client_unix_user,
    group  => $dtk_client_unix_user,
    mode   => 700
  }

  exec { "ssh-keygen":
    command => "ssh-keygen -t rsa -f ${ssh_path} -P ''",
    user    => $dtk_client_unix_user,
    path    => ['/usr/bin'],
    creates => $ssh_path,
  }

  exec { "add_source":
    command => "gem source --add $gem_source",
    path    => ['/usr/bin']
  }

  package {'dtk-client':
    provider => gem,
    ensure => installed,
  }

  file { "/home/${dtk_client_unix_user}/.gitconfig":
    ensure => 'present',
    owner  => $dtk_client_unix_user,
    content => template('dtk_client/gitconfig.erb')
  }

  dtk_client::git_repo_keyscan { $server_host:
    username => $dtk_client_unix_user,
   }

  File["/home/${dtk_client_unix_user}/dtk"] -> File["/home/${dtk_client_unix_user}/dtk/.connection"] -> File["/home/${dtk_client_unix_user}/dtk/client.conf"] -> File["/home/${dtk_client_unix_user}/.ssh"] -> Exec['ssh-keygen'] -> Exec['add_source'] -> Package['dtk-client'] -> File["/home/${dtk_client_unix_user}/.gitconfig"]
}

