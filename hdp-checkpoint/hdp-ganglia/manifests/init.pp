class hdp-ganglia()
{
  include hdp-ganglia::params
  $gmetad_user = $hdp-ganglia::params::gmetad_user
  $gmond_user = $hdp-ganglia::params::gmond_user
  
  user { $gmond_user : shell => '/bin/bash'} #provision for nobody user
  if ( $gmetad_user != $gmond_user) {
    user { $gmetad_user : shell => '/bin/bash'} #provision for nobody user
  }
  anchor{'hdp-ganglia::begin':} -> User<|title == $gmond_user or title == $gmetad_user|> ->  anchor{'hdp-ganglia::end':}
}

class hdp-ganglia::service::gmond(
  $ensure = undef,
  )
{
  service { 'hdp-gmond':
    ensure     => $ensure,
    hasstatus  => false,
    hasrestart => true
  }
}

class hdp-ganglia::service::gmetad(
  $ensure = undef)
{
  service { 'hdp-gmetad':
    ensure     => $ensure,
    hasstatus  => false,
    hasrestart => true
  }
}
