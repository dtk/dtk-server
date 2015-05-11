class dtk_thin::base() 
{
  package { 'thin': 
	ensure 	 => installed,
	provider => gem
	}
}

