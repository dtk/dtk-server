#This resource is used to establish ssh tunnel if rspec tests and rspec db are on two different machines
class dtk_addons::remote(
  $source_user,
  $destination_user,
  $destination_password,
  $source_port = 5433,
  $destination_port = 5432,
  $destination_host
)
{
  #To provide ssh connection with password inline, installing sshpass package
  package { 'sshpass':
    ensure => 'installed',
  }

  #Install postgresql client package to be able to connect to pg server
  package { 'postgresql-client':
    ensure => 'installed',
  }

  exec { 'establish_ssh_tunnel':
    command => "nohup sshpass ssh -i /home/${source_user}/rsa_identity_dir/id_rsa -o StrictHostKeyChecking=no -L ${source_port}:localhost:${destination_port} ${destination_host} -l ${destination_user} -N &",
    user    => $source_user,
    path    => [ "/usr/local/bin/", "/bin/", "/usr/bin/"],
    require => Package['sshpass']
  }
}

