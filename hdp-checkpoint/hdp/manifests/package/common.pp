define hdp::package::common(
  $httpd = false,
  $php = false,
  $net-snmp-perl = false,
  $perl-net-snmp = false
)
{
  $beg = "hdp::package::common::${name}::begin"
  $end = "hdp::package::common::${name}::end"
  anchor{$beg:}
  anchor{$end:}
  
  if ($httpd == true) {
    package { 'httpd':}
    Anchor[$beg] -> Package['httpd'] -> Anchor[$end]
  }
  if ($php == true) {
    package { 'php':}
    Anchor[$beg] -> Package['php'] -> Anchor[$end]
  }
  if ($net-snmp-perl == true) {
    package { 'net-snmp-perl':}
    Anchor[$beg] -> Package['net-snmp-perl'] -> Anchor[$end]
  }
  if ($perl-net-snmp == true) {
    package { 'perl-Net-SNMP':}
    Anchor[$beg] -> Package['perl-Net-SNMP'] -> Anchor[$end]
  }

  #put any common package dependencies here
}