define dtk_client::ssh_config(
  $app_user,
)
{
  $repo_target_dir = "/home/${app_user}"
  $rsa_identity_dir = "${repo_target_dir}/target"
  $repo_url = "git@github.com:rich-reactor8/dtk-client.git"
  $identity = "${rsa_identity_dir}/id_rsa"

  file { $rsa_identity_dir:
    ensure => 'directory',
    owner  => $app_user
  }

  file { "${rsa_identity_dir}/id_rsa":
    ensure => 'present',
    mode   => '0600',
    owner  => $app_user,
    source => 'puppet:///modules/dtk_client/ssh/id_rsa'
  }

  file { "${rsa_identity_dir}/id_rsa.pub":
     ensure => 'present',
     mode   => '0644',
     owner  => $app_user,
     source => 'puppet:///modules/dtk_client/ssh/id_rsa.pub'
  }

  exec { "add_privileges_for_known_hosts":
    command => "chown ${app_user}:${app_user} ${repo_target_dir}/.ssh/known_hosts",
    path    => [ "/usr/local/bin/", "/bin/" ],
    environment => ["USER=/root"],
  }

  file { "${repo_target_dir}/dtk-client":
     ensure => absent,
     force  => true
  }

  vcsrepo { "${repo_target_dir}/dtk-client":
     ensure   => 'present',
     owner    => $app_user,
     group    => $app_user,
     user     => $app_user,
     provider => 'git',
     source   => $repo_url,
     revision => 'master',
     identity => $identity,
  }

  File[$rsa_identity_dir] -> File["${rsa_identity_dir}/id_rsa"] -> File["${rsa_identity_dir}/id_rsa.pub"] -> Exec["add_privileges_for_known_hosts"] -> File["${repo_target_dir}/dtk-client"] -> Vcsrepo["${repo_target_dir}/dtk-client"]
}