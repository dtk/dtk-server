 ./utility/clear_db.sh ; ./utility/dbrebuild.rb ; ./utility/initialize.rb --delete; ./utility/add_user.rb joe
 ./utility/add_user.rb joe --create-private stdlib,hdp,hdp-hadoop,hdp-zookeeper,hdp-hbase,hdp-nagios,hdp-ganglia,hdp-dashboard,hdp-monitor-webserver
 ./utility/add_user.rb joe --create-private mysql,hdp-mysql,hdp-hcat,hdp-hive,hdp-pig,hdp-sqoop
 ./utility/add_user.rb joe --create-private kerberos,hdp-java-jce
 ./utility/add_user.rb joe --create-private gitolite,dtk_repo_manager,thin










