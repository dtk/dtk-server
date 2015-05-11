class dtk_passenger::repo()
{
    case $::osfamily {
      'Debian': {
        if !defined(Class['apt']) {
          class { 'apt': }
        }
        apt::source { 'passenger':
          location          => 'https://oss-binaries.phusionpassenger.com/apt/passenger',
          release           => $::lsbdistcodename,
          repos             => 'main',
          required_packages => 'apt-transport-https',
          key               => '561F9B9CAC40B2F7',
          key_server        => 'keyserver.ubuntu.com',
          include_src       => false
        }
      }
      'RedHat', 'Linux': {
        include epel
        yumrepo { 'passenger':
          descr      => 'passenger',
          baseurl    => "http://passenger.stealthymonkeys.com/rhel/\$releasever/\$basearch",
          mirrorlist => 'http://passenger.stealthymonkeys.com/rhel/mirrors',
          gpgcheck   => 1,
          gpgkey     => 'http://passenger.stealthymonkeys.com/RPM-GPG-KEY-stealthymonkeys',
          enabled    => 1,
        }
      }
      default: {
        fail("\"${module_name}\" provides no package information for OSfamily \"${::osfamily}\"")
      } 
    }
}