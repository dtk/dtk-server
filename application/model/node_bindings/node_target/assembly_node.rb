module DTK; class NodeBindings
  class NodeTarget
    class AssemblyNode
      def initialize(hash)
        @assembly_name = hash[:assembly_name]
        @node_name = hash[:node_name]
      end
      def hash_form()
        {:assembly_name => @assembly_name, :node_name => @node_name} 
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

      def self.class_of?(parse_input)
        if parse_input.type?(String)
          input = parse_input.input
          input.split('/').size == 3 and input =~ /^assembly\//
        end
      end
      def self.parse_and_reify(parse_input)
        input = parse_input.input
        split = input.split('/')
        assembly_name = split[1]
        node_name = split[2]
        new(:assembly_name => assembly_name,:node_name => node_name)
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

    end
  end
end; end
