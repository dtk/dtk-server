#!/usr/bin/env bash
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

chown -R dtk1:dtk1 /home/dtk1
chown -R git1:git1 /home/git1

if [[ -s /dtk-creds/creds ]]; then
  su - 'dtk1' -c 'bash /init.sh'
  cat /dev/null > /dtk-creds/creds
fi

rm -rf /var/run/nginx/nginx.sock

/usr/bin/supervisord