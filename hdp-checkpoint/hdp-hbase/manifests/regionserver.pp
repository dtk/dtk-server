class hdp-hbase::regionserver(
  $service_state = running,
  $ganglia_host = undef,
  $nagios_host = undef,
  $opts = {}
) 
{
  if ($opts[wait] == undef) {
    $wait = 25
  } else {
    $wait = $opts[wait]
  }      
  @hdp-hbase::common { 'hbase': }
  hdp-hbase::service{ 'regionserver':
    enable       => $service_state,
    initial_wait => $wait
  }

  #top level does not need anchors
  Hdp-hbase::Common<|master != true|> -> Hdp-hbase::Service['regionserver']
}

