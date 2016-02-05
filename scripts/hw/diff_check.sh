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
cd /root/r8server-repo/joe-puppet-hdp-pig
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-nagios
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-ganglia
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-dashboard
git checkout project-private-joe-v1

cd /root/r8server-repo
diff -r joe-puppet-hdp /root/R8Server/hdp-checkpoint/hdp
diff -r joe-puppet-hdp-hadoop/ /root/R8Server/hdp-checkpoint/hdp-hadoop/
diff -r joe-puppet-hdp-zookeeper/ /root/R8Server/hdp-checkpoint/hdp-zookeeper/
diff -r joe-puppet-hdp-hbase/ /root/R8Server/hdp-checkpoint/hdp-hbase/
diff -r joe-puppet-hdp-hcat/ /root/R8Server/hdp-checkpoint/hdp-hcat/
diff -r joe-puppet-hdp-pig/ /root/R8Server/hdp-checkpoint/hdp-pig/
diff -r joe-puppet-hdp-nagios/ /root/R8Server/hdp-checkpoint/hdp-nagios/
diff -r joe-puppet-hdp-ganglia/ /root/R8Server/hdp-checkpoint/hdp-ganglia/
diff -r joe-puppet-hdp-dashboard/ /root/R8Server/hdp-checkpoint/hdp-dashboard/