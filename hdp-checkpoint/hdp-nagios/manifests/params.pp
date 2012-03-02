class hdp-nagios::params() inherits hdp::params
{
  $nagios_rpm_url = hdp_default("nagios_rpm_url","http://pkgs.repoforge.org/nagios/nagios-3.2.3-3.el5.rf.x86_64.rpm")
}