#
# Classes that encapsulate information for each module or moulde branch where is its location clone and where is its remotes
#
module DTK
  class ModuleBranch
    class Location
      r8_nested_require('location','params')
      # above needed before below
      r8_nested_require('location','local')
      r8_nested_require('location','remote')
      # above needed before below
      r8_nested_require('location','server')
      r8_nested_require('location','client')

      attr_reader :local,:remote

      private

      def initialize(project,local_params=nil,remote_params=nil)
        if local_params
          @local = self.class::Local.new(project,local_params)
        end
        if remote_params
          @remote = self.class::Remote.new(project,remote_params)
        end
      end
    end
  end
end
