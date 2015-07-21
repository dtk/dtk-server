class dtk_user::params()
{
  $sshd_config_path = '/etc/ssh/sshd_config'
  $sshd_service = $operatingsystem ? {
    /(?i-mx:ubuntu|debian)/        => 'ssh',
    /(?i-mx:centos|fedora|redhat)/ => 'sshd'
  }
  
  $sudo_config_file = '/etc/sudoers'
  $sudo_config_dir = '/etc/sudoers.d/'
}