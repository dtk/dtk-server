class thin::service(
)
{
  file { '/etc/init.d/thin':
    content => template('thin/thin.init.erb'),
    mode    => 'o+x',
  }

  file { '/etc/thin/':
    ensure => 'directory'
  }
    service { 'thin':
    ensure  => true,
    enable  => true,
    require => File['/etc/init.d/thin']
  }
}