cd /root/r8server-repo/joe-puppet-hdp
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-hadoop
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-zookeeper
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-hbase
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-hcat
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-hive
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-pig
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-oozie
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-nagios
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-ganglia
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-dashboard
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-monitor-webserver
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-mysql
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-mysql
git checkout project-private-joe-v1

cd /root/r8server-repo
diff -r joe-puppet-hdp ~/core-cookbooks/puppet/hdp
diff -r joe-puppet-hdp-hadoop/ ~/core-cookbooks/puppet/hdp-hadoop/
diff -r joe-puppet-hdp-zookeeper/ ~/core-cookbooks/puppet/hdp-zookeeper/
diff -r joe-puppet-hdp-hbase/ ~/core-cookbooks/puppet/hdp-hbase/
diff -r joe-puppet-hdp-hcat/ ~/core-cookbooks/puppet/hdp-hcat/
diff -r joe-puppet-hdp-hive/ ~/core-cookbooks/puppet/hdp-hive/
diff -r joe-puppet-hdp-pig/ ~/core-cookbooks/puppet/hdp-pig/
diff -r joe-puppet-hdp-oozie/ ~/core-cookbooks/puppet/hdp-oozie/
diff -r joe-puppet-hdp-nagios/ ~/core-cookbooks/puppet/hdp-nagios
diff -r joe-puppet-hdp-ganglia/ ~/core-cookbooks/puppet/hdp-ganglia
diff -r joe-puppet-hdp-dashboard/ ~/core-cookbooks/puppet/hdp-dashboard
diff -r joe-puppet-hdp-monitor-webserver/ ~/core-cookbooks/puppet/hdp-monitor-webserver
diff -r joe-puppet-hdp-mysql/ ~/core-cookbooks/puppet/hdp-mysql
diff -r joe-puppet-mysql/ ~/core-cookbooks/puppet/mysql



