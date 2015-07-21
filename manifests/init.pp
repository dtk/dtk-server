class dtk_client(
  $dtk_client_unix_user,
  $gem_source_location,
  $dtk_client_username,
  $dtk_client_password,
  $dtk_server_host = "dtk16.dtk.io",
  $dtk_server_port = "7000",
  $dtk_server_secure_connection_port = "443",
  $dtk_server_secure_connection = "true",
  $git_config_user_name = "test",
  $git_config_user_email = "test@reactor8.com",
  $install_from_rvm_location = "",
  $release = false,
)
{
  dtk_client::install { $dtk_client_unix_user:
    gem_source                    => $gem_source_location,
    username                      => $dtk_client_username,
    password                      => $dtk_client_password,
    server_host                   => $dtk_server_host,
    server_port                   => $dtk_server_port,
    secure_connection_server_port => $dtk_server_secure_connection_port,
    secure_connection             => $dtk_server_secure_connection,
    git_config_user_name          => $git_config_user_name,
    git_config_user_email         => $git_config_user_email,
    install_from_rvm_location     => $install_from_rvm_location,
    release                       => $release
  }
}

define dtk_client::git_repo_keyscan(
  $username = 'root',
  )
{
  $git_hostname = $name

  if $username == "root" {
    $homedir = "/root"
  }
  else {
    $homedir = "/home/${username}"
  }
  
  $touch_file = "/tmp/ssh-keyscan-${git_hostname}-${username}"
  exec { "dtk_server::repo_keyscan ${name}":
    command => "ssh-keyscan ${git_hostname} >> ${homedir}/.ssh/known_hosts; touch ${touch_file}",
    creates => $touch_file,
    path    => ['/usr/bin'],

  }
}
