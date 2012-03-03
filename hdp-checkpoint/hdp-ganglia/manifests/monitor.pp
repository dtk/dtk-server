class hdp-ganglia::monitor()
{
  hdp::package { 'ganglia-monitor' : provider => 'yum'}
}