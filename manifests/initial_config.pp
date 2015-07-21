#TODO: rewrite to leverage admin_client
define gitolite::initial_config()
{

  $gitolite_user = $name
  $gitolite_homedir = "/home/${gitolite_user}"  
  $server_admin_repo = "${gitolite_homedir}/gitolite-admin"
  $configs_dir = "${server_admin_repo}/conf/repo-configs"
  $gitolite_conf = "${server_admin_repo}/conf/gitolite.conf"
  $group_defs_dir = "${server_admin_repo}/conf/group-defs"

  anchor { "gitolite::initial_config::begin ${gitolite_user}": }

  #create a gitolie-admin clone
  exec { "clone ${server_admin_repo}":
    command => "git clone ${gitolite_user}@localhost:gitolite-admin ${server_admin_repo}",
    cwd     => $gitolite_homedir,
    user    => $gitolite_user,
    creates => $server_admin_repo,
    path    => ['/usr/bin'],
    require => Anchor["gitolite::initial_config::begin ${gitolite_user}"]
  }

  file { $gitolite_conf:
    content => template('gitolite/gitolite.conf.erb'),
    owner   => $gitolite_user,
    require => Exec["clone ${server_admin_repo}"]
  }  

  file { [$configs_dir,$group_defs_dir]:
    ensure  => 'directory',
    owner   => $gitolite_user,
    require => Exec["clone ${server_admin_repo}"] 
  } 

  file { "${configs_dir}/testing.conf":
    content => template('gitolite/testing.conf.erb'),
    owner   => $gitolite_user,
    require => File[$configs_dir]
  }  

  gitolite::add_group_def { "admin-${gitolite_user}":
    gitolite_user => $gitolite_user,
    group_name    => 'admin',
    group_member  => $gitolite_user,
    require       => File[$group_defs_dir]
  }  

  #TODO: look at using a git command to determine if these should be run rather than a refresh
  $add_cmd = "git add ."
  $config_name_cmd = "git config user.name ${gitolite_user}"
  $config_email_cmd = "git config user.email ${gitolite_user}@dtk.io"
  $commit_cmd = "git commit -a -m 'initial update'"
  gitolite::git_command { "gitolite::initial_config commit ${gitolite_user}":
    command     => "${config_name_cmd}; ${config_email_cmd}; ${add_cmd}; ${commit_cmd}",
    user        => $gitolite_user,
    repo_dir    => $server_admin_repo,
    refreshonly => true,
    subscribe   => [File["${configs_dir}/testing.conf"],File[$gitolite_conf],Gitolite::Add_group_def["admin-${gitolite_user}"]]
  }
  
   gitolite::git_command { "gitolite::initial_config push ${gitolite_user}":
    command     => "git push origin master",
    user        => $gitolite_user,
    repo_dir    => $server_admin_repo,
    refreshonly => true,
    subscribe   => Gitolite::Git_command["gitolite::initial_config commit ${gitolite_user}"],
    before      => Anchor["gitolite::initial_config::end ${gitolite_user}"]
  }

  anchor { "gitolite::initial_config::end ${gitolite_user}": }
}