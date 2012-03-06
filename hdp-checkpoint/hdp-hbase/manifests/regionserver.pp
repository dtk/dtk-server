class hdp-hbase::regionserver(
  $service_state = running,
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
) 
{
  $hdp::params::service_exists['hdp-hbase::regionserver'] = true
  
  if ($opts[wait] == undef) {
    $wait = 25
  } else {
    $wait = $opts[wait]
  }      
  @hdp-hbase::common { 'hbase': }
  hdp-hbase::service{ 'regionserver':
    ensure       => $service_state,
    initial_wait => $wait
  }

  #top level does not need anchors
  Hdp-hbase::Common<|master != true|> -> Hdp-hbase::Service['regionserver']
}
