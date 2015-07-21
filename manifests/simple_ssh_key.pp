define dtk_user::simple_ssh_key(
  $rsa_pub_key,
  $sudo_access,
  $manage_user = true
)
{
  $username = $name

  if ($manage_user == true) {
    user { $username:
      ensure     => 'present',
      shell      => '/bin/bash',
      managehome => true
    }
  }

  $key = inline_template('<%= rsa_pub_key.gsub(/^.*ssh-rsa /,"").gsub(/ .+$/,"") %>') 

  #TODO: need to change to manage multiple keys
  ssh_authorized_key { $username:
    ensure  => 'present',
    key     => $key,
    user    => $username,
    type    => 'ssh-rsa',
    require => User[$username]
  }

  if ($sudo_access == 'true') {
    dtk_user::add_sudo_access{ $username:}
  }
}