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
module DTK
  class RepoManager::Git
    class GitCommand
      def initialize(grit_git)
        @grit_git = grit_git
      end
      
      def method_missing(name, *args, &block)
        @grit_git.send(name, *args, &block)
      rescue ::Grit::Git::CommandFailed => e
        # e.err empty is being interpretad as no error
        if e.err.nil? || e.err.empty?
          Log.info("::Grit non zero exit status #{e.exitstatus} but grit err field is empty for command='#{e.command}'")
        else
          # write more info to server log, but to client return user friendly message
          Log.info("::Grit error: #{e.err} exitstatus=#{e.exitstatus}; command='#{e.command}'")
          error_msg = "::Grit error: #{e.err.strip()}"
          raise ErrorUsage.new(error_msg)
        end
      rescue => e
        raise e
      end
      
      def respond_to?(name)
        !!(@grit_git.respond_to?(name) || super)
      end
      
    end
  end
end
