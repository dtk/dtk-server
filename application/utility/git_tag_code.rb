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
require 'pp'

# no stdout buffering
STDOUT.sync = true

# checks for windows/unix for chaining commands
OS_COMMAND_CHAIN = RUBY_PLATFORM =~ /mswin|mingw|cygwin/ ? '&' : ';'

unless ARGV[0]
  print 'You need to pass version tag as param to script call'
  exit(1)
end

puts 'WARNING!'
puts
puts '************* PROVIDED DATA *************'
puts " VERSION TAG:    #{ARGV[0]}"
puts '*****************************************'
puts 'Make sure that provided data is correct, and press ENTER to continue OR CTRL^C to stop'
a = $stdin.gets

# ['dtk-common-repo','dtk-common',

['dtk-common-repo', 'dtk-common', 'server', 'dtk-repo-manager', 'dtk-repoman-admin', 'dtk-node-agent'].each do |entry|
  if File.directory? File.join('.', entry)
    puts "Skipping '#{entry}' already exists"
  else
    puts `git clone #{PREFIX_R8SERVER_SSH_URL}#{entry}.git`
  end
end