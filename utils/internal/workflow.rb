#require 'ruote'
#require 'ruote/storage/fs_storage'

module XYZ
  class Workflow
    def self.create_workflow(action_list)
      self.new(action_list)
    end
   private
    def initialize(action_list)
      #if all the actions have the same
      if Action.actions_are_concurrent?(action_list)
      end
    end
  end
end
