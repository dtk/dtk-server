class dtk_repo_manager::passenger (
  $ruby_path = undef,
)
{

#file { "/etc/apt/sources.list.d/passenger.list":
#        ensure => present,
#        owner => root,
#        content => "deb https://oss-binaries.phusionpassenger.com/apt/passenger ${::lsbdistcodename} main",
#}

apt::source { 'passenger':
  location          => 'https://oss-binaries.phusionpassenger.com/apt/passenger',
  release           => $::lsbdistcodename,
  repos             => 'main',
  required_packages => 'apt-transport-https',
  key               => '561F9B9CAC40B2F7',
  key_server        => 'keyserver.ubuntu.com',
  include_src       => false
}

#exec { "apt-get update":
#        command => "/usr/bin/apt-get update",
#        require => Apt::Source["passenger"],
#}

package { ["nginx-full", "passenger"]:
  ensure => installed,
	require => Apt::Source["passenger"],
}

file { "/etc/nginx/conf.d/passenger.conf":
	content => template("dtk_repo_manager/passenger.conf.erb"),
	require => [Package["nginx-full"], Package["passenger"]];
}

}
