#singleton, but using define so can use collections to override params
define hdp-hadoop::package(
  $include_32_bit=false,
  $include_64_bit=false
)
{
  if (($include_32_bit == true) and ($include_64_bit == true)) {
    hdp_fail("Cannot install both 32 and 64 bit hadoop")
  }
  anchor{ 'hdp-hadoop::package::helper::begin': }
  anchor{ 'hdp-hadoop::package::helper::end': }
  if ($include_32_bit == true) {
    hdp::package{ 'hadoop 32' :
      package_type => 'hadoop',
      size         => 32,
      included     => true #TODO: see if we can get rid of included
    }
    Anchor['hdp-hadoop::package::helper::begin'] -> Hdp::Package['hadoop 32'] -> Anchor['hdp-hadoop::package::helper::end']
  }
  if ($include_64_bit == true) {
    hdp::package{ 'hadoop 64' :
      package_type => 'hadoop',
      size     => 64,
      included => true #TODO: see if we can get rid of included
    }
    Anchor['hdp-hadoop::package::helper::begin'] -> Hdp::Package['hadoop 64'] -> Anchor['hdp-hadoop::package::helper::end']
  }
}
  