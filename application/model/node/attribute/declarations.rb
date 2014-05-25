module DTK; class Node
  class NodeAttribute::Def
    class PuppetVersion < self
    end
    Attribute 'node_agent.puppet.version', PuppetVersion do
      aliases ['puppet_version']
      data_type :string
      types lambda{|v|ConfigAgent.treated_version?(:puppet,v)}
      #TODO: put in meta attribute cannot_change_after_converge
    end
    Attribute 'foo' do
      data_type :string
    end
  end
end; end
