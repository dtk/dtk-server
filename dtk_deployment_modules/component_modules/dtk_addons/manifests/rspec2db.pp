class dtk_addons::rspec2db(
  $user,
  $rspec2db_repo = "https://github.com/ATLANTBH/rspec"
)
{
  
  $repo_target_dir = "/home/${user}/rspec"

  package { 'rspec':
    ensure   => 'installed',
    provider => 'gem',
  }

  /*
  exec { 'git_clone_rspec2db_repo':
    command => "git clone ${rspec2db_repo}",
    user    => $user,
    cwd     => "/home/${user}",
    path    => ['/usr/bin'],
  }
  */

  vcsrepo { $repo_target_dir: 
    ensure   => 'present',
    owner    => $user, 
    group    => $user,
    user     => $user,
    provider => 'git', 
    source   => $rspec2db_repo,
    revision => 'master',
  }

  exec { 'rspec2db_build':
    command => "gem build rspec2db.gemspec",
    user    => $user,
    cwd     => "/home/${user}/rspec",
    path    => ['/usr/bin'],
  }

  exec { 'rspec2db_gem_install':
    command => "gem install rspec2db-*",
    cwd     => "/home/${user}/rspec",
    path    => ['/usr/bin'],
  }

  #This is needed in case when pg gem is not been installed yet.
  #Its a prerequisite for installation of pg gem
  #If pg gem already exist, this command will not be executed
  exec { 'install_libpg-dev':
    command => "sudo apt-get install libpq-dev -y",
    onlyif  => "gem list pg | grep -c -v pg",
    path    => [ "/usr/local/bin/", "/bin/", "/usr/bin/"]
  }

  exec { 'rspec2db_bundle_install':
    command => "bundle install",
    cwd     => "/home/${user}/rspec",
    path    => ['/usr/bin','/usr/local/bin'],
  }

  Package['rspec'] ->  Vcsrepo[$repo_target_dir] -> Exec['rspec2db_build'] -> Exec['rspec2db_gem_install'] -> Exec['install_libpg-dev'] -> Exec['rspec2db_bundle_install']
}
