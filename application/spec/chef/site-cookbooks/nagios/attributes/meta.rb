#
# Author:: Rich Pelavin
set[:nagios][:service_check_assocs]=Mash.new

set[:nagios][:service_check_assocs][:mysql_basic_health] = {
  :service_description => "mysql",
  :command_name => "check_mysql",
  :command_line => "$USER1$/check_mysql -H $HOSTADDRESS$ -u $ARG1$ -p $ARG2$",
  :ARG1 => "params[:monitor_user_id]",
  :ARG2 => "params[:db_info].find{|x|x[:username] == params[:monitor_user_id]}[:password]"
}

set[:nagios][:service_check_assocs][:redis_basic_health] = {
  :service_description => "redis",
  :command_name => "check_redis",
  :command_line => "$USER1$/check_redis -H $HOSTADDRESS$ -p $ARG1$",
  :ARG1 => "sap_inet_port(params[:sap])",
  :is_custom_check => "server_side",
  :required_gem_packages => %w{redis SystemTimer}
}

set[:nagios][:service_check_assocs][:rabbitmq_basic_health] = {
  :service_description => "rabbitmq",
  :command_name => "check_rabbitmq_overall",
  :command_line => "$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_rabbitmq_overall -t 20",
  :is_custom_check => "client_side",
  :client_side => {
    :command_line => "/usr/lib/nagios/plugins/check_rabbitmq_overall",
    :attributes_file => "rabbitmq/attributes.data"
  }
}

set[:nagios][:service_check_assocs][:check_hadoop_datanode_remotely] = {
  :service_description => "hadoop_datanode",
  :command_name => "check_hadoop_datanode_remotely",
  # TBD: make command_line parametrizable by ports 
  :command_line => "$USER1$/check_http -H $HOSTADDRESS$ -u 'http://$HOSTADDRESS$:50075/browseDirectory.jsp?namenodeInfoPort=50070&dir=/' -p 50075 -r HDFS"
}

set[:nagios][:service_check_assocs][:check_hadoop_namenode_remotely] = {
  :service_description => "hadoop_namenode",
  :command_name => "check_hadoop_namenode_remotely",
  # TBD: make command_line parametrizable by ports 
  :command_line => "$USER1$/check_http -H $HOSTADDRESS$ -u http://$HOSTADDRESS$:50070/dfshealth.jsp -p 50070 -r NameNode"
}

# TBD: convert others to this form
check="check_hadoop_dfs"
set[:nagios][:service_check_assocs][check] = {
  :service_description => "hadoop_dfs",
  :command_name => check,
  :command_line => "$USER1$/check_nrpe -H $HOSTADDRESS$ -c #{check} -t 20",
  :is_custom_check => "client_side",
  :client_side => {:command_line => "/usr/lib/nagios/plugins/#{check}"}
}
check="check_hadoop_namenode_jmx"
set[:nagios][:service_check_assocs][check] = {
  :service_description => "hadoop_namenode_jmx",
  :command_name => check,
  :command_line => "$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_jmx_hadoop_namenode  -t 20",
  :is_custom_check => "client_side",
  :client_side => {
    :command_name => "check_jmx_hadoop_namenode",
    :plugin_name => "check_jmx_attributes",
    :command_line => "/usr/lib/nagios/plugins/check_jmx_attributes -F hadoop_namenode.data -p $ARG1$ -P $ARG2$",
    :ARG1 => "params[:jmxremote_port]",
    :ARG2 => "params[:jmxremote_password]",
    :attributes_file => "jmx_attributes_files/hadoop_namenode.data",
    :required_support_files => %w{jmxquery.jar}
  }
}
check="chesire_http_test1"
set[:nagios][:service_check_assocs][:chesire_http_test1] = {
  :service_description => "chesire_http",
  :command_name => check,
  :command_line => "$USER1$/check_http -H $HOSTADDRESS$ -u /reports/funnel/14/2009-06-24/2009-06-25 -s success"
}

