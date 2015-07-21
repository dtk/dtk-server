#TODO: not needed if not using pw access
#TODO: wil need also to load ruby gem to manipulate /etc/shadow
class dtk_user::sshd(
  $ssh_pw_enabled
) inherits dtk_user::params
{
 if $ssh_pw_enabled == 'true' {
   $ssh_pw_state  = 'yes'
   $ssh_pw_opp_state  = 'no'
 } else {
   $ssh_pw_state  = 'no'
   $ssh_pw_opp_state  = 'yes'
 }

 #if see any presence of opposiet state deleet all PasswordAuthentication 
 #and add desired one
 #TODO: does not work if config does not have PasswordAuthentication mentioned in any line
 $onlyif = "grep 'PasswordAuthentication ' ${sshd_config_path} | grep ${ssh_pw_opp_state}"
 $cmd_rmv_lines = "sed -i '/PasswordAuthentication /d' ${sshd_config_path}"
 $cmd_add_line = "echo 'PasswordAuthentication ${ssh_pw_state}' >> ${sshd_config_path}"
 exec { 'ssh_pw_enabled dtk_user::base':
   command => "${cmd_rmv_lines}; ${cmd_add_line}",
   onlyif  => $onlyif,
   path    => ['/bin'] 
 }
 
  service { $sshd_service:
    ensure    => running,
    enable    => true,
    hasstatus => true,
    subscribe => [Exec['ssh_pw_enabled dtk_user::base']]
  }

}

