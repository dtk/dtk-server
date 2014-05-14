module DTK; class Node
  class NodeAttribute
    Attribute 'node_agent.puppet.version' do
#      aliases ['puppet_version']
      data_type :string
      types lambda{|x|ConfigAgent.treated_version?(:puppet,x)}
      #TODO: put in meta attribute cannot_change_after_converge
    end
  end
end; end
