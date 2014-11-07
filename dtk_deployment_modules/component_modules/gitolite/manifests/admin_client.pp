define gitolite::admin_client(
  $client_name,
  $gitolite_user
)
{
  include gitolite::params
  $gitolite_homedir = "/home/${gitolite_user}"

  $admin_user = $client_name
  $admin_user_homedir = "/home/${$admin_user}"
  $admin_repo = "${admin_user_homedir}/gitolite-admin"

  $admin_user_ssh_dir = "${admin_user_homedir}/.ssh"

  anchor { "gitolite::admin_client::${client_name}::begin": }
  #generate ssh keys
  file { $admin_user_ssh_dir:
    ensure  => 'directory',
    owner   => $admin_user,
    require => Anchor["gitolite::admin_client::${client_name}::begin"]
  }

  exec { "gitolite ssh-keygen ${client_name}":
    command => "ssh-keygen -q -t rsa -f ${admin_user_ssh_dir}/id_rsa -N '' ",
    user    => $admin_user,
    creates => "${admin_user_homedir}/.ssh/id_rsa.pub",
    path    => ['/usr/bin'],
    require => File[$admin_user_ssh_dir]
  }

  #set known hosts
  $admin_known_hosts = "${admin_user_ssh_dir}/known_hosts"
  file { $admin_known_hosts:
    ensure  => present,
    owner   => $admin_user,
    require => File[$admin_user_ssh_dir]
  }

  exec { "set known_hosts ${client_name}":
    command => "ssh-keyscan localhost >> ${admin_known_hosts}",
    unless  => "grep 'localhost' ${admin_known_hosts}",
    path    => ['/bin','/usr/bin'],
    require => File[$admin_known_hosts]
  }

  gitolite::authorize_as_admin { $admin_user:
    gitolite_user => $gitolite_user,
    require       => [Exec["gitolite ssh-keygen ${client_name}","set known_hosts ${client_name}"]]
  }

  #create a gitolie-admin clone
  exec { "clone ${admin_repo}  ${client_name}":
    command => "git clone ${gitolite_user}@localhost:gitolite-admin ${admin_repo}",
    cwd     => $admin_user_homedir,
    user    => $admin_user,
    creates => $admin_repo,
    path    => ['/usr/bin'],
    require => Gitolite::Authorize_as_admin[$admin_user],
    before  => Anchor["gitolite::admin_client::${client_name}::end"]
  }

  anchor { "gitolite::admin_client::${client_name}::end": }
}
