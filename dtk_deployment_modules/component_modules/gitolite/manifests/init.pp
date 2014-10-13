#sets up gitolite server and an admin under the server user account
define gitolite(
  $gitolite_user
)
{
  include gitolite::params

  $gitolite_homedir = "/home/${gitolite_user}"  

  $install_bin = "${gitolite_homedir}/bin"
  $server_admin_pub_key = "${gitolite_homedir}/.ssh/id_rsa.pub"
  
  gitolite::package { $name:
    gitolite_user => $gitolite_user,
    install_dir   => "${gitolite_homedir}/src",
    install_bin   => $install_bin
  }

  exec { "gitolite ssh-keygen ${gitolite_user}":
    command => "ssh-keygen -q -t rsa -f ${gitolite_homedir}/.ssh/id_rsa -N '' ",
    user    => $gitolite_user,
    creates => $server_admin_pub_key,
    path    => ['/usr/bin']
  }

  $copied_key = "/tmp/${gitolite_user}.pub"
  $cp_cmd = "cp ${server_admin_pub_key} ${copied_key}"
  $chown_cmd = "chown ${gitolite_user} ${copied_key}"
  $setup_cmd = "su - ${gitolite_user} -c '${install_bin}/gitolite setup -pk ${copied_key}'"
  exec { "gl-setup-${gitolite_user}":
    command => "${cp_cmd}; ${chown_cmd}; ${setup_cmd}",
    creates => $copied_key, #TODO: need better test detecting if setup_cmd fails
    path    => ['/bin']
  }

  $admin_known_hosts = "${gitolite_homedir}/.ssh/known_hosts"
  $host_rsa_public = $::sshrsakey
  exec { "set known_hosts ${gitolite_user}" :
    command => "echo 'localhost,127.0.0.1 ssh-rsa ${host_rsa_public}' >> ${admin_known_hosts}",
    user    => $gitolite_user,
    unless  =>  "grep 'localhost,127.0.0.1' ${admin_known_hosts}",
    path    => ['/bin']
  }

  gitolite::initial_config { $gitolite_user: }
  
  Common_user[$name] -> Gitolite::Package[$name] -> Exec["gitolite ssh-keygen ${gitolite_user}"] -> 
   Exec["gl-setup-${gitolite_user}"] -> Exec["set known_hosts ${gitolite_user}"] -> Gitolite::Initial_config[$gitolite_user] 
}

define gitolite::add_group_def(
  $gitolite_user,
  $group_name,
  $group_member
) 
{
  $gitolite_homedir = "/home/${gitolite_user}"
  $server_admin_repo = "${gitolite_homedir}/gitolite-admin"
  
  file { "${server_admin_repo}/conf/group-defs/${name}.conf":
    content => template('gitolite/group-defs/group-def.conf.erb'),
    owner   => $gitolite_user
  }  
}

define gitolite::package(
  $install_dir,
  $install_bin,
  $gitolite_user  
)
{
  $gitolite_git_source = $gitolite::params::gitolite_git_source
  
   exec { "gitolite::package git clone ${name}":
    command => "git clone ${gitolite_git_source} ${install_dir}",
    path => ['/usr/bin'],
    user => $gitolite_user,
    creates => $install_dir
  }

  file { $install_bin:
    ensure => 'directory',
    owner  => $gitolite_user
  }

  exec { "gitolite::package install ${gitolite_user}":
    command => "${install_dir}/install -ln ${install_bin}"
  }

  anchor{"gitolite::package::begin ${gitolite_user}":} -> File[$install_bin] -> Exec["gitolite::package git clone ${name}"] -> 
    Exec["gitolite::package install ${gitolite_user}"] ->  anchor{"gitolite::package::end ${gitolite_user}":}
}

define gitolite::git_command(
  $user,
  $repo_dir,
  $command,
  $refreshonly = undef
)
{
   exec { $name:
    command     => $command,
    path        => ['/usr/bin'],
    user        => $user,
    cwd         => $repo_dir,
    logoutput   => true,
    refreshonly => $refreshonly
  }
}


define gitolite::authorize_as_admin(
  $gitolite_user
)
{
  $admin_user = $name
  $gitolite_homedir = "/home/${gitolite_user}"

  $server_admin_repo = "${gitolite_homedir}/gitolite-admin"
  $admin_git_name = "dtk-admin-${admin_user}"
  
  anchor { "gitolite::authorize_as_admin::${name}::begin": }
  
  #copy admin_user public key to gitolite dir
  $copy_src = "/home/${admin_user}/.ssh/id_rsa.pub"
  $copy_target = "${server_admin_repo}/keydir/${admin_git_name}.pub"
  $copy_cmd = "cp ${copy_src} ${copy_target}"
  $chown_cmd = "chown ${gitolite_user} ${copy_target}"
  exec { $copy_cmd:
    command => "${copy_cmd}; ${chown_cmd}",
    creates => $copy_target, 
    path    => ['/bin'],
    require => Anchor["gitolite::authorize_as_admin::${name}::begin"]
  }
  
  gitolite::add_group_def { "admin-${admin_git_name}":
    gitolite_user => $gitolite_user,
    group_name    => 'admin',
    group_member  => $admin_git_name,
    require       => Anchor["gitolite::authorize_as_admin::${name}::begin"]
  }  
 
  #add, commit and push
  $add_cmd = "git add ."
  $config_name_cmd = "git config user.name ${gitolite_user}"
  $commit_cmd = "git commit -a -m 'adding admin access for ${admin_user}'"
  
  #TODO: look at using a git command to determien if these shoudl be run rather than a refresh
  gitolite::git_command { "gitolite::authorize_as_admin ${name} commit":
    command     => "${add_cmd};${commit_cmd}",
    user        => $gitolite_user,
    repo_dir    => $server_admin_repo,
    refreshonly => true,
    subscribe   => [Exec[$copy_cmd], Gitolite::Add_group_def["admin-${admin_git_name}"]]
  }
  
   gitolite::git_command { "gitolite::authorize_as_admin ${name} push":
    command     => "git push origin master",
    user        => $gitolite_user,
    repo_dir    => $server_admin_repo,
    refreshonly => true,
    subscribe   => Gitolite::Git_command["gitolite::authorize_as_admin ${name} commit"],
    before      => Anchor["gitolite::authorize_as_admin::${name}::end"]
  }
  
  anchor { "gitolite::authorize_as_admin::${name}::end": }
}

 
