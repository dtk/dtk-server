#TODO: handle this be generic sudo module
#needed so can delete the actual repo from the repo_manager_account
class dtk_repo_manager::sudo()
{
  $admin_user = $dtk_repo_manager::params::admin_user

  $sudo_file = "/etc/sudoers"
  $sudo_config_dir = "/etc/sudoers.d"

  anchor { 'dtk_repo_manager::sudo::begin':}

  $sudo_include_line = "#includedir ${sudo_config_dir}"
  exec {'dtk_repo_manager::sudo update base':
    command => "echo '${sudo_include_line}' >> ${sudo_file}",
    path    => ['/bin'],
    unless  => "grep '${sudo_include_line}' ${sudo_file}",
    require => Anchor['dtk_repo_manager::sudo::begin'],
    before  => Anchor['dtk_repo_manager::sudo::end']
  }

  #TODO: provide much more restricted rights
  $allow_command = "${admin_user} ALL=(ALL) NOPASSWD:ALL"

  file { "${sudo_config_dir}/${admin_user}" :
    content => $allow_command,
    mode    => '0440',
    require => Anchor['dtk_repo_manager::sudo::begin'],
    before  => Anchor['dtk_repo_manager::sudo::end']
  }

  anchor { 'dtk_repo_manager::sudo::end': }
} 