define dtk_server::bundler_gems_install(
  $app_user,
)
{
  $gemfile_dir = $name
  $vendor_dir  = "/var/lib/dtk-bundler-vendor"

  exec { "bundle install ${gemfile_dir}":
    command   => "/usr/local/rvm/wrappers/default/bundle install --deployment --path=$vendor_dir",
    cwd       => $gemfile_dir,
    path      => ['/usr/bin','/usr/local/bin/', '/bin'],
    logoutput => 'on_failure',
    #user      => $app_user,
    timeout   => 500,
    require   => File[$vendor_dir]
  }

  file { $vendor_dir:
    ensure    => directory,
    #owner    => $app_user,
    #group     => $app_user,
  }

}

define dtk_server::github_repo(
  $app_user,
  $app_user_homedir,
  $branch = 'master',
  $identity = undef
)
{
   #$repo = $name
   $repo = regsubst($name, $app_user, '')
   include dtk_server::params
   $repo_url = $dtk_server::params::repo_urls[$repo]
   $target = $dtk_server::params::repo_targets[$repo]
   $repo_target_dir = "${app_user_homedir}/${target}"

   file { $repo_target_dir:
     ensure => absent,
     force  => true
   }

   vcsrepo { $repo_target_dir: 
     ensure   => 'present',
     owner    => $app_user, 
     group    => $app_user,
     user     => $app_user,
     provider => 'git', 
     source   => $repo_url,
     revision => $branch,
     identity => $identity,
     submodules => false,
     require  => File[$repo_target_dir]
   }
}

define dtk_server::git_repo_keyscan()
{
  $git_hostname	= $name
  $touch_file = "/tmp/ssh-keyscan-${git_hostname}"
  exec { "dtk_server::repo_keyscan ${name}":
    command => "ssh-keyscan ${git_hostname} >> /root/.ssh/known_hosts; touch ${touch_file}",
    creates => $touch_file,
    path    => ['/usr/bin', '/bin']
  }
}
