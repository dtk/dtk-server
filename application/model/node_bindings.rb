module DTK
  class NodeBindings
    r8_nested_require('node_bindings','dsl')
    r8_nested_require('node_bindings','target')

    def self.create_linked_target_ref?(target,node,assembly_template_idh)
      unless R8::Config[:test_node_bindings]
        return nil
      end
      if node_bindings = get_node_bindings(assembly_template_idh)
        assembly_instance,node_instance = node_bindings.find_matching_instance_info(target,node)
        if node_instance
          Node::TargetRef::Input::BaseNodes.create_linked_target_ref?(target,node_instance,assembly_instance)
        end
      end
    end
    def initialize(hash)
      @parsed_form = parse_and_reify(hash)
    end

    #returns if match [assembly_instance,node_instance]
    def find_matching_instance_info(target,node)
      if single_node = @parsed_form[node.get_field?(:display_name)]
        single_node.find_matching_instance_info(target,node)
      end
    end

    def self.parse(parse_input)
      unless parse_input.type?(Hash)
        raise parse_input.error("Node Bindings section has an illegal form: ?input")
      end
      #TODO: check each node belongs to assembly
      ret = parse_input.input.inject(Hash.new) do |h,(node,node_target)|
        h.merge(node => Target.parse(parse_input.child(node_target)))
      end
      pp [:debug_parse,ret]
      ret
    end


   private
    def self.get_node_bindings(assembly_template_idh)
      #TODO: this will be in object model; here we get it from the following file on server under /tmp/nodes_bindings.yaml
      #whose syntax is at bottom of this file
      if hash = File.exists?(StubFile) && Aux.convert_to_hash(File.open(StubFile).read,:yaml)
        ['assembly','node_bindings'].each do |key|
          unless hash[key]
            raise ErrorUsage.new("Node binding missing #{key} key")
          end
        end
        if hash['assembly'] == Assembly::Template.pretty_print_name(assembly_template_idh.create_object)
          new(hash['node_bindings'])
        end
      end
    end
    StubFile = '/tmp/nodes_bindings.yaml'
    
    def parse_and_reify(hash)
      hash.inject(Hash.new) do |h,(node,binding)|
        h.merge(node => SingleNode.new(binding))
      end
    end

    class SingleNode 
      def initialize(binding)
        hash = parse_and_reify(binding)
        @assembly_name = hash[:assembly_name]
        @node_name = hash[:node_name]
      end

      #returns if match [assembly_instance,node_instance]
      def find_matching_instance_info(target,stub_node)
        #see if in target there is an assembly that matches @assembly
        assembly_instances = find_matching_assembly_instances(target)
        if assembly_instances.size == 0
          Log.info('no node binding matches found')
          return nil
        elsif assembly_instances.size > 1
          Log.info('multiple node binding matches found')
          return nil
        end
        assembly_instance = assembly_instances.first
        matching_node_instance = assembly_instance.get_nodes().find do |n|
          n.get_field?(:display_name) == @node_name
        end
        unless matching_node_instance
          raise ErrorUsage.new("Assembly (#{assembly_instance[:display_name]}) does not have node (#{@node_name})")
        end
        unless matching_node_instance.get_field?(:type) == 'instance'
          raise ErrorUsage.new("Assembly (#{assembly_instance[:display_name]}) node (#{@node_name}) cannot be matched because it is just staged")
        end
        [assembly_instance,matching_node_instance]
      end

     private
      def find_matching_assembly_instances(target)
        sp_hash = {
          :cols => [:id,:display_name,:instance_parent],
          :filter => [:eq,:datacenter_datacenter_id,target.id()]
        }   
        Assembly::Instance.get_objs(target.model_handle(:assembly_instance),sp_hash).select do |r|
          @assembly_name == Assembly::Template.pretty_print_name(r[:assembly_template])
        end
      end

      def parse_and_reify(binding) 
        split = binding.split('/')
        unless split.size == 3
          raise ErrorUsage.new("Unexpected that binding does not have form: TYPE/ASSEMBLY-REF/NODE-REF")
        end
        type,assembly,node = split
        unless type == 'assembly'
          raise ErrorUsage.new("Only type == 'assembly' is treated")
        end
        {
          :assembly_name => assembly,
          :node_name     => node
        }
      end
    end
  end
end

=begin
Strawman how node bindings will look when in service module
$:~/dtk/service_modules/test_shared_nodes/assemblies/tenant>cat node_bindings.yaml
---
The following would match on an asssembly test_shared_nodes::tenant and for node node1 in this assembly
would set it so that it uses the node node2 from deployed service instance from assembly template test_shared_nodes::base

assembly: test_shared_nodes::tenant 
node_bindings:
  node1:
    assembly/test_shared_nodes::base/node2
=end 
