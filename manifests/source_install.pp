define dtk_client::source_install(
  $app_user,
  $install_from_rvm_location
)
{
  $repo_target_dir = "/home/${app_user}"

  exec { "dtk_client_bundle_install":
    command   => "${install_from_rvm_location}/bundle install --path vendor/bundle",
    user      => $app_user,
    environment => ["USER=${app_user}", "HOME=${repo_target_dir}"],
    logoutput => 'on_failure',
    cwd       => "${repo_target_dir}/dtk-client",
  }

  exec { "dtk_client_build_gemspec":
    command => "${install_from_rvm_location}/gem build dtk-client.gemspec",
    user    => $app_user,
    environment => ["USER=${app_user}", "HOME=${repo_target_dir}"],
    cwd     => "${repo_target_dir}/dtk-client"
  }

  exec { "dtk_client_install":
    command => "${install_from_rvm_location}/gem install dtk-client-* --no-rdoc --no-ri",
    environment => ["HOME=${repo_target_dir}"],
    cwd     => "${repo_target_dir}/dtk-client"
  }

  Exec['dtk_client_bundle_install'] -> Exec['dtk_client_build_gemspec'] -> Exec['dtk_client_install']
}