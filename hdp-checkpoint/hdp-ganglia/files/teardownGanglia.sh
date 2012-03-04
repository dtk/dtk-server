#!/bin/sh

# Copyright 2011, Hortonworks Inc.  All rights reserved.
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

cd `dirname ${0}`;

# Get access to Ganglia-wide constants, utilities etc.
source ./gangliaLib.sh;

# Undo what we did while setting up Ganglia on this box.
rm -rf ${GANGLIA_CONF_DIR};
rm -rf ${GANGLIA_RUNTIME_DIR};
