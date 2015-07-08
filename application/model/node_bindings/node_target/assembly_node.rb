module DTK; class NodeBindings
  class NodeTarget
    class AssemblyNode < self
      def initialize(hash)
        super(Type)
        @assembly_name = hash[:assembly_name]
        @assembly_name_internal_form = @assembly_name.gsub(/::/,'/')
        # TODO: encapsulate sepeartor between service mod and assembly in Assembly::Template
        @node_name = hash[:node_name]
      end
      Type = :assembly_node
      def hash_form
        {type: type().to_s, assembly_name: @assembly_name, node_name: @node_name}
      end

      def self.parse_and_reify(parse_input,_opts={})
        ret = nil
        if parse_input.type?(ContentField)
          input = parse_input.input
          if input[:type].to_sym == Type
            ret = new(input)
          end
        elsif parse_input.type?(String)
          input = parse_input.input
          if input.split('/').size == 3 && input =~ /^assembly\//
            split = input.split('/')
            assembly_name = split[1].gsub(/::/,'/')
            node_name = split[2]
            ret = new(assembly_name: assembly_name,node_name: node_name)
          end
        end
        ret
      end

      #returns if match [assembly_instance,node_instance]
      def find_matching_instance_info(target,_stub_node)
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
          cols: [:id,:display_name,:instance_parent],
          filter: [:eq,:datacenter_datacenter_id,target.id()]
        }
        Assembly::Instance.get_objs(target.model_handle(:assembly_instance),sp_hash).select do |r|
          if assembly_template = r[:assembly_template]
            @assembly_name_internal_form == Assembly::Template.pretty_print_name(assembly_template)
          end
        end
      end
    end
  end
end; end
