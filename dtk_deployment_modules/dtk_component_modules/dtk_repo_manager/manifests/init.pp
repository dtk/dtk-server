class dtk_repo_manager(
  $rails_env = 'production',
  $repoman_dns_address = 'repoman1.dtk.io',
  $admin_dns_address   = 'admin1.dtk.io',
  # can also be branch or commit sha
  $repoman_tag = 'master',
  $repoman_admin_tag = 'master',
  $dtk_common_tag = 'master',
  $dtk_common_core_tag = 'master',
)
{
  include dtk_repo_manager::params
  include rvm
  $gitolite_user = $dtk_repo_manager::params::gitolite_user
  $admin_user = $dtk_repo_manager::params::admin_user
  #$app_repos = $dtk_repo_manager::params::app_repos
  $utilities_base = $dtk_repo_manager::params::utilities_base
  $rvm_path = "/usr/local/rvm"
  $rvm_ruby_version = "ruby-1.9.3-p484"

  $gitolite_user_homedir = $dtk_repo_manager::params::gitolite_user_homedir

  #$repo = 'repo_manager'
  #$target = $dtk_repo_manager::params::repo_info[$repo]
  #$test_var =  $dtk_repo_manager::params::repo_info[admin][target_dir]
  $repo_target_dir = "${gitolite_user_homedir}/${dtk_repo_manager::params::repo_info[repo_manager][target_dir]}"
  $admin_target_dir = "${gitolite_user_homedir}/${dtk_repo_manager::params::repo_info[admin][target_dir]}"
 
  package { 'libpq-dev': 
    ensure => 'installed'
  }

  package { 'nodejs':
    ensure => installed,
  }

  package { 'redis-server':
    ensure => installed,
  }

  service {'redis-server':
    ensure  => running,
    require => Package['redis-server'],
  }

  dtk_repo_manager::rvm { $rvm_ruby_version: }

  class { 'nginx::config':}

  class { "dtk_repo_manager::passenger":
     ruby_path => "${rvm_path}/wrappers/default/ruby",
     require   => Dtk_repo_manager::Rvm[$rvm_ruby_version],
  }

  #repoman vhost
  nginx::resource::vhost { $repoman_dns_address:
    www_root            => "${repo_target_dir}/public",
    index_files         => undef,
    ssl                 => true,
    ssl_cert            => "puppet:///modules/dtk_repo_manager/dtk.io_combined.crt",
    ssl_key             => "puppet:///modules/dtk_repo_manager/wildcard.dtk.io.key",
    ssl_dhparam         => "puppet:///modules/dtk_repo_manager/dhparam.pem",
    ssl_protocols       => "TLSv1 TLSv1.1 TLSv1.2 SSLv3",
    ssl_ciphers         => "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK",
    ssl_stapling        => "on",
    ssl_stapling_verify => "on",
    ssl_cache           => "shared:SSL:50m",
    ssl_trusted_certificate    => "puppet:///modules/dtk_repo_manager/dtk.io_combined.crt",
    rewrite_to_https    => true,
    add_header          => ["Strict-Transport-Security max-age=15768000"],
    vhost_cfg_append    => {
      'passenger_enabled'       => 'on',
      'rails_env'               =>  $rails_env,
      'server_name'             => "localhost ${::ec2_public_hostname}",
    },
    require => Class["dtk_repo_manager::passenger"],
  }

  #admin vhost
  nginx::resource::vhost { $admin_dns_address:
    www_root            => "${admin_target_dir}/public",
    index_files         => undef,
    ssl                 => true,
    ssl_cert            => "puppet:///modules/dtk_repo_manager/dtk.io_combined.crt",
    ssl_key             => "puppet:///modules/dtk_repo_manager/wildcard.dtk.io.key",
    ssl_dhparam         => "puppet:///modules/dtk_repo_manager/dhparam.pem",
    ssl_protocols       => "TLSv1 TLSv1.1 TLSv1.2 SSLv3",
    ssl_ciphers         => "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK",
    ssl_stapling        => "on",
    ssl_stapling_verify => "on",
    ssl_cache           => "shared:SSL:50m",
    ssl_trusted_certificate    => "puppet:///modules/dtk_repo_manager/dtk.io_combined.crt",
    rewrite_to_https    => true,
    add_header          => ["Strict-Transport-Security max-age=15768000"],
    vhost_cfg_append    => {
      'passenger_enabled' => 'on',
      'rails_env'         =>  $rails_env,
      'passenger_set_cgi_param REPOMAN_HOST' => 'localhost',
      'passenger_set_cgi_param REPOMAN_PORT' => '443',
    },
    require => Class["dtk_repo_manager::passenger"],
  }

  exec { "bundle_update":
    command    => "/usr/local/rvm/wrappers/default/bundle update",
    cwd        => $repo_target_dir,
    logoutput  => true,
    require    => [ Dtk_repo_manager::Github_repo[$dtk_repo_manager::params::repoman_repo], Dtk_repo_manager::Rvm[$rvm_ruby_version] ]
  }

  exec { "bundle_install":
    command    => "/usr/local/rvm/wrappers/default/bundle install",
    cwd        => $repo_target_dir,
    logoutput  => true,
    require    => [ Dtk_repo_manager::Github_repo[$dtk_repo_manager::params::repoman_repo], Dtk_repo_manager::Rvm[$rvm_ruby_version], Exec["bundle_update"] ]
  }

  exec { "bundle_install_admin":
    command    => "/usr/local/rvm/wrappers/default/bundle install",
    cwd        => $admin_target_dir,
    logoutput  => true,
    require    => [ Dtk_repo_manager::Github_repo[$dtk_repo_manager::params::repoman_admin_repo], Dtk_repo_manager::Rvm[$rvm_ruby_version], Package["nodejs"] ]
  }

  exec { "rake_assets_precompile_admin":
    environment => ["RAILS_ENV=${rails_env}", "REPOMAN_HOST=localhost", "REPOMAN_PORT=443"],
    command => "/usr/local/rvm/wrappers/default/rake assets:precompile",
    user    => $gitolite_user,
    cwd     => $admin_target_dir,
    require => Exec["bundle_install_admin"],
  }

  exec { "rake_db_create":
    command => "/usr/local/rvm/wrappers/default/rake db:create",
    user  => $gitolite_user,
    cwd     => $repo_target_dir,
    require => [Exec["bundle_install"], Package["nodejs"]],
  }

  exec { "rake_db_migrate":
    command => "/usr/local/rvm/wrappers/default/rake db:migrate",
    user    => $gitolite_user,
    cwd     => $repo_target_dir,
    require => Exec["rake_db_create"],
  }

  exec { "rake_db_seed":
    command => "/usr/local/rvm/wrappers/default/rake db:seed ci:seed",
    user    => $gitolite_user,
    cwd     => $repo_target_dir,
    require => Exec["rake_db_migrate"],
  }

  file { "/etc/init.d/sidekiq":
    content => template("dtk_repo_manager/sidekiq.init.erb"),
    mode    => "o+x",
    require => Exec["rake_db_seed"],
  }

  service { "sidekiq":
    enable      => true,
    ensure      => running,
    #hasstatus   => true,
    hasrestart  => true,
    require     => [ File["/etc/init.d/sidekiq"], Service["redis-server"] ],
  }

  
  if ($gitolite_user != $admin_user) {
    class { 'dtk_repo_manager::sudo':}
  }

  # gitolite hooks setup
  file { "${gitolite_user_homedir}/.dtk_environment":
    ensure => 'present',
    owner  => $gitolite_user,
    source => 'puppet:///modules/dtk_repo_manager/dtk_environment',
    before => Exec["${gitolite_user}-setup"],
  }

  file { "${gitolite_user_homedir}/.gitolite/hooks/common/post-receive":
    ensure  => 'present',
    owner   => $gitolite_user,
    source  => "${repo_target_dir}/script/gitolite/hooks/post-receive",
    mode    => 'ugo+x',
    require => Dtk_repo_manager::Github_repo[$dtk_repo_manager::params::repoman_repo],
    before  => Exec["${gitolite_user}-setup"],
  }

  # enable the hooks
  exec { "${gitolite_user}-setup":
    command   => "${gitolite_user_homedir}/bin/gitolite setup",
    user      => $gitolite_user,
    logoutput => "on_failure",
    cwd       => $gitolite_user_homedir,
    environment => "HOME=${gitolite_user_homedir}",
  }

  file { "${gitolite_user_homedir}/repositories/gitolite-admin.git/hooks/post-receive":
    ensure  => absent,
    require => Exec["${gitolite_user}-setup"],
  }

  class { 'dtk_repo_manager::rsa_identity_dir':
    require => Common_user[$gitolite_user]
  }

  dtk_repo_manager::github_repo { $dtk_repo_manager::params::repoman_repo:
    repo_branch => $repoman_tag,
    require => Class['dtk_repo_manager::rsa_identity_dir']
  }

  dtk_repo_manager::github_repo { $dtk_repo_manager::params::repoman_admin_repo:
    repo_branch => $repoman_admin_tag,
    require => Class['dtk_repo_manager::rsa_identity_dir']
  }

  dtk_repo_manager::github_repo { $dtk_repo_manager::params::dtk_common_repo:
    repo_branch => $dtk_common_tag,
    require => Class['dtk_repo_manager::rsa_identity_dir']
  }

  dtk_repo_manager::github_repo { $dtk_repo_manager::params::dtk_common_core_repo:
    repo_branch => $dtk_common_core_tag,
    require => Class['dtk_repo_manager::rsa_identity_dir']
  }
}

define dtk_repo_manager::github_repo(
  $repo_branch,
)
{
  $repo = $name
  include dtk_repo_manager::params
  #TODO: may convert to using create-resource
  $repo_url = $dtk_repo_manager::params::repo_info[$repo][repo_url]
  $target = $dtk_repo_manager::params::repo_info[$repo][target_dir]
  $branch = $repo_branch
  $gitolite_user = $dtk_repo_manager::params::gitolite_user
  $gitolite_user_homedir = $dtk_repo_manager::params::gitolite_user_homedir
     
  $repo_target_dir = "${gitolite_user_homedir}/${target}"
  $rsa_identity_dir = $dtk_repo_manager::params::rsa_identity_dir

  vcsrepo { $repo_target_dir: 
    ensure   => 'present',
    owner    => $gitolite_user, 
    group    => $gitolite_user,
    user     => $gitolite_user,
    provider => 'git', 
    source   => $repo_url,
    revision => $branch,
    identity => "${rsa_identity_dir}/id_rsa"
  }
}

define dtk_repo_manager::rvm()
{
  $ruby_version = $name

  include rvm
  rvm_system_ruby {
    $ruby_version:
    ensure      => 'present',
    default_use => true,
    # looks like 1.9.3 binaries are no longer available
    # or mybe not
    build_opts  => ['--binary'];
  }
}

class dtk_repo_manager::rsa_identity_dir()
{
  include dtk_repo_manager::params
  $gitolite_user = $dtk_repo_manager::params::gitolite_user
  $rsa_identity_dir = $dtk_repo_manager::params::rsa_identity_dir
  file { $rsa_identity_dir:
    ensure => 'directory'
  }   

  file { "${rsa_identity_dir}/id_rsa":
    ensure => 'present',
    mode   => '0600',
    owner  => $gitolite_user,
    source => 'puppet:///modules/dtk_repo_manager/ssh/id_rsa'
   }

   file { "${rsa_identity_dir}/id_rsa.pub":
     ensure => 'present',
     mode   => '0644',
     owner  => $gitolite_user,
     source => 'puppet:///modules/dtk_repo_manager/ssh/id_rsa.pub'
   }
}
