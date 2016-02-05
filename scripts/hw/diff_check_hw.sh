#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
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
cd /root/r8server-repo/joe-puppet-hdp-sqoop
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
diff -r joe-puppet-hdp ~/HMC/src/puppet/modules/hdp
diff -r joe-puppet-hdp-hadoop/ ~/HMC/src/puppet/modules/hdp-hadoop/
diff -r joe-puppet-hdp-zookeeper/ ~/HMC/src/puppet/modules/hdp-zookeeper/
diff -r joe-puppet-hdp-hbase/ ~/HMC/src/puppet/modules/hdp-hbase/
diff -r joe-puppet-hdp-hcat/ ~/HMC/src/puppet/modules/hdp-hcat/
diff -r joe-puppet-hdp-hive/ ~/HMC/src/puppet/modules/hdp-hive/
diff -r joe-puppet-hdp-pig/ ~/HMC/src/puppet/modules/hdp-pig/
diff -r joe-puppet-hdp-oozie/ ~/HMC/src/puppet/modules/hdp-oozie/
diff -r joe-puppet-hdp-sqoop/ ~/HMC/src/puppet/modules/hdp-sqoop/
diff -r joe-puppet-hdp-nagios/ ~/HMC/src/puppet/modules/hdp-nagios
diff -r joe-puppet-hdp-ganglia/ ~/HMC/src/puppet/modules/hdp-ganglia
diff -r joe-puppet-hdp-dashboard/ ~/HMC/src/puppet/modules/hdp-dashboard
diff -r joe-puppet-hdp-monitor-webserver/ ~/HMC/src/puppet/modules/hdp-monitor-webserver
diff -r joe-puppet-hdp-mysql/ ~/HMC/src/puppet/modules/hdp-mysql
diff -r joe-puppet-mysql/ ~/HMC/src/puppet/modules/mysql