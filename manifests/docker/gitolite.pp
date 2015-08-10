class dtk_server::docker::gitolite (
  $tenant_user,
  $tenant_internal='dtk1',
  $gitolite_host
)
{

  include dtk_server::docker::params

  $tenant_directory="${dtk_server::docker::params::volume_base}/${tenant_user}"
  $tenant_directory_ssh="${tenant_directory}/.ssh"
  $gitolite_user="${tenant_user}-git"
  $gitolite_homedir="${tenant_directory}/${tenant_user}-git"
  $install_bin = "${gitolite_homedir}/bin"
  $server_admin_pub_key = "${gitolite_homedir}/.ssh/id_rsa.pub"
  $server_admin_pub_key_named = "${gitolite_homedir}/.ssh/${gitolite_user}.pub"
  $server_admin_repo = "${gitolite_homedir}/gitolite-admin"
  $gitolite_conf = "${server_admin_repo}/conf/gitolite.conf"

  user { $gitolite_user: ensure => present, home => $gitolite_homedir, managehome => true,}->
  exec { "gitolite ssh-keygen ${gitolite_user}":
      command => "ssh-keygen -q -t rsa -f ${gitolite_homedir}/.ssh/id_rsa -N '' ",
      user    => $gitolite_user,
      creates => $server_admin_pub_key,
      path    => ['/usr/bin']
    }->
  vcsrepo { "${gitolite_homedir}/gitolite":
    ensure   => present,
    provider => git,
    source   => "https://github.com/sitaramc/gitolite",
    owner    => $gitolite_user,
    group    => $gitolite_user,
  }->
  file { $server_admin_pub_key_named:
    ensure => present,
    source => $server_admin_pub_key,
  }->
    file { [$install_bin,"${gitolite_homedir}/logs", "${gitolite_homedir}/.gitolite",  "${gitolite_homedir}/.gitolite/logs"] :
      ensure => 'directory',
      owner  => $gitolite_user,
      group => $gitolite_user,
    }->
  exec { 'gitolite install':
    command => "${gitolite_homedir}/gitolite/install -ln",
    user => $gitolite_user,
    environment => ["HOME=${gitolite_homedir}"],
    creates => "${install_bin}/gitolite",
  }->
  exec { 'gitolite setup':
    command => "${install_bin}/gitolite setup -pk ${server_admin_pub_key_named}",
    user => $gitolite_user,
    environment => ["HOME=${gitolite_homedir}"],
    creates => "${gitolite_homedir}/repositories/gitolite-admin.git",
  }->
  exec { 'gitolite keyscan admin':
    command => "/usr/bin/ssh-keyscan ${gitolite_host} >> ${gitolite_homedir}/.ssh/known_hosts",
    unless => "/bin/grep ${gitolite_host} ${gitolite_homedir}/.ssh/known_hosts",
    user => $gitolite_user,
  }->
  exec { 'gitolite keyscan tenant admin':
    command => "/usr/bin/ssh-keyscan ${gitolite_host} >> ${tenant_directory_ssh}/known_hosts",
    unless => "/bin/grep ${gitolite_host} ${tenant_directory_ssh}/known_hosts",
    #user => $gitolite_user,
  }->
  exec { 'gitolite clone admin':
    command => "/usr/bin/git clone ${gitolite_user}@${gitolite_host}:gitolite-admin ${server_admin_repo}",
    user => $gitolite_user,
    creates => $server_admin_repo,
  }->
  gitolite_group_defs { [$gitolite_user, "dtk-admin-${tenant_internal}"]:
      gitolite_user => $gitolite_user,
      group_name    => 'admin',
      server_admin_repo => $server_admin_repo,
  }->
    file { $gitolite_conf:
      content => template('gitolite/gitolite.conf.erb'),
      owner   => $gitolite_user,
  }->
  file { "${server_admin_repo}/keydir/dtk-admin-${tenant_internal}.pub":
    ensure => present,
    source => "${tenant_directory_ssh}/id_rsa.pub",
    owner  => $gitolite_user,
    group => $gitolite_user,
  }->
  exec { 'push gitolite admin':
    cwd => $server_admin_repo,
    command => "git config user.name ${gitolite_user} && git add . && git commit -a -m 'automatic push' && git push",
    user => $gitolite_user,
    unless => "git status | grep 'nothing to commit'",
    path => ['/usr/bin', '/bin'],
  }->
  #exec { 'gitolite admin clone for tenant':
  #  command => "/usr/bin/git clone ${gitolite_user}@${gitolite_host}:gitolite-admin ${tenant_directory}/${tenant_internal}/gitolite-admin"
  #  user => $gitolite_user,
  #  creates => "${tenant_directory}/${tenant_internal}/gitolite-admin/.git",
  #}
  vcsrepo { "${tenant_directory}/home/gitolite-admin":
    ensure   => present,
    provider => git,
    source   => "${gitolite_user}@${gitolite_host}:gitolite-admin",
    identity => "${tenant_directory_ssh}/id_rsa",
  }
}

define gitolite_group_defs(
  $group_name,
  $group_member = $name,
  $server_admin_repo,
  $gitolite_user
)
{
  if ! defined (File["${server_admin_repo}/conf/group-defs"]) {
  file { "${server_admin_repo}/conf/group-defs":
    ensure => directory,
    owner  => $gitolite_user,
    group => $gitolite_user,
    before => File["${server_admin_repo}/conf/group-defs/${name}.conf"],
  }
  }

  file { "${server_admin_repo}/conf/group-defs/${name}.conf":
    content => template('gitolite/group-defs/group-def.conf.erb'),
    owner   => $gitolite_user
  }
}


