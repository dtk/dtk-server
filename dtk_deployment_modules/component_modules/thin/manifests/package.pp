class thin::package(
) 
{
	  package { 'thin':
    ensure => installed,
    provider => gem,
  }		
}