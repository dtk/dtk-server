define dtk_server::bundler_gems_install()
{
  $gemfile_dir = $name

  exec { "bundle install ${gemfile_dir}":
    command   => "bundle install",
    cwd       => $gemfile_dir,
    path      => ['/usr/bin','/usr/local/bin/'],
    logoutput => 'on_failure'
  }
}

#TODO: change to real app deployment; this only works when right keys already on node
define dtk_server::github_repo(
  $app_user,
  $app_user_homedir,
  $branch = 'master_candidate' #TODO: incorporate cloning initially or switching to this branch
)
{
   $repo = $name
   include dtk_server::params
   $repo_url = $dtk_server::params::repo_urls[$repo]
   $target = $dtk_server::params::repo_targets[$repo]
 
   $repo_target_dir = "${app_user_homedir}/${target}"
   $git_clone_cmd = "git clone -b ${branch} ${repo_url} ${repo_target_dir}"
   $chown_cmd = "chown -R ${app_user} ${repo_target_dir}"
   
   exec { "dtk_server clone ${name}":
     command   => "${git_clone_cmd}; ${chown_cmd}",
     path      => ['/bin','/usr/bin'],
     logoutput => true,
     creates   => $repo_target_dir
   } 
}

define dtk_server::git_repo_keyscan()
{
  $git_hostname	= $name
  $touch_file = "/tmp/ssh-keyscan-${git_hostname}"
  exec { "dtk_server::repo_keyscan ${name}":
    command => "ssh-keyscan ${git_hostname} >> /root/.ssh/known_hosts; touch ${touch_file}",
    creates => $touch_file,
    path    => ['/usr/bin']
  }
}