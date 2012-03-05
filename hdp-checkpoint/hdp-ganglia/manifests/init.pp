class hdp-ganglia(){}

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