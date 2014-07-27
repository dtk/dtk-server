module DTK; class Node; class TargetRef
  class Input 
    class BaseNodes < self

      # This creates links between node instances and target refs
      # to_link_hash is of form {node_instance1_id => target_ref, ..}
      def self.link_to_target_refs(target,to_link_hash)
        create_ngrs_objs_hash = to_link_hash.inject(Hash.new) do |h,(node_instance_id,target_ref)|
          h.merge(target_ref_link_hash(node_instance_id,target_ref.id))
        end
        create_objs_hash = {:node_group_relation => create_ngrs_objs_hash}
        Model.input_hash_content_into_model(target.id_handle(),create_objs_hash)
      end

      #This creates if needed a new target ref, links node to it and moves the node's attributes to the target ref
      def self.create_linked_target_ref?(target,node,assembly)
        ndx_node_target_ref_array = create_linked_target_refs?(target,assembly,[node])
        unless target_ref_array = ndx_node_target_ref_array[node[:id]]
          raise Error.new("Unexpected that create_linked_target_ref does not return element matching node[:id]")
        end
        unless target_ref_array.size == 1
          raise Error.new("Unexpected that ndx_node_target_ref_array.size not equal 1")
        end
        target_ref = target_ref_array.first.create_object()
        #TODO: can be more efficienct and avoid calling below if create_linked_target_refs? finds as opposed to creates
        # target refs
        move_node_attributes_to_target_refs(target,[{:node_instance => node,:target_ref => target_ref}])
        target_ref
      end

      # This creates if needed target refs and links nodes to them
      # returns new idhs indexed by node (id) they linked to
      # or if they exist their idhs
      # for any node that is node group, this copies the node group's attributes to the target refs
      def self.create_linked_target_refs?(target,assembly,nodes)
        ret = Hash.new
        ndx_target_ref_idhs = TargetRef.ndx_matching_target_ref_idhs(:node_instance_idhs => nodes.map{|n|n.id_handle})

        create_objs_hash = Hash.new
        nodes.each do |node|
          node_id = node[:id]
          cardinality = node.attribute.cardinality
          target_ref_idhs = ndx_target_ref_idhs[node_id]||[]
          num_needed = cardinality - target_ref_idhs.size
          if num_needed > 0
            el = Element.new(:node => node,:num_needed => num_needed)
            el.add_target_ref_and_ngr!(create_objs_hash,target,assembly)
          elsif num_needed == 0
            if cardinality > 0
              ret.merge!(node_id => target_ref_idhs)
            end
          else # num_needed < 0
            Log.error("Unexpected that more target refs than needed")
            ret.merge!(node_id => target_ref_idhs)
          end
        end

        unless create_objs_hash.empty?
          all_idhs = Model.input_hash_content_into_model(target.id_handle(),create_objs_hash,:return_idhs => true)
          #all idhs have both nodes and node_group_rels
          ngr_idhs = all_idhs.select{|idh|idh[:model_name] == :node_group_relation}
          copy_node_group_attrs_to_target_refs?(target,nodes,ngr_idhs)
          ret.merge!(TargetRef.ndx_matching_target_ref_idhs(:node_group_relation_idhs => ngr_idhs))
        end
        ret
      end

     private
      # to_link_array is of form [{:node_instance => node,:target_ref => target_ref},..]
      def self.move_node_attributes_to_target_refs(target,to_link_array)
        return if to_link_array.empty?
        sp_hash = {
          :cols => [:id,:display_name,:node_node_id],
          :filter => [:oneof,:node_node_id,to_link_array.map{|n|n[:node_instance].id()}]
        }
        attr_mh = target.model_handle(:attribute)
        attrs = Model.get_objs(attr_mh,sp_hash)
        return if attrs.empty?
        to_link_hash = to_link_array.inject(Hash.new){|h,r|h.merge(r[:node_instance].id => r[:target_ref].id)}
        rows_to_update = attrs.map do |r|
          {:id => r[:id], :node_node_id => to_link_hash[r[:node_node_id]]}
        end
        Log.error("need to also update top.id_info since parent field is being updated")
        Model.update_from_rows(attr_mh,rows_to_update)
      end

      def self.copy_node_group_attrs_to_target_refs?(target,nodes,ngr_idhs)
        node_groups = nodes.select{|n|n.is_node_group?()}
        return if node_groups.empty?
        
        ng_idhs = node_groups.map{|ng|ng.id_handle()}
        ndx_ng_target_ref_attrs = Hash.new
        ServiceNodeGroup.get_attributes_to_copy_to_target_refs(ng_idhs).each do |ng_attr|
          node_group_id = ng_attr.delete(:node_node_id)

          target_ref_attr = Hash.new
          ng_attr.each do |field,val|
            if field == :type
              target_ref_attr[field] = Node::Type.target_ref
            else
              #remove nil fields
              target_ref_attr[field] = val unless val.nil?
            end
          end

          (ndx_ng_target_ref_attrs[node_group_id] ||= Array.new) << target_ref_attr
        end

        sp_hash = {
          :cols => [:node_id,:node_group_id],
          :filter => [:oneof,:id,ngr_idhs.map{|idh|idh.get_id()}]
        }
        ngr_mh = target.model_handle(:node_group_relation)
        create_rows = Array.new
        Model.get_objs(ngr_mh,sp_hash).each do |ngr|
          node_group_id = ngr[:node_group_id]
          unless target_ref_attrs = ndx_ng_target_ref_attrs[ngr[:node_group_id]]
            Log.error("Unexpected that node group id is not found in node_group_refs")
            next
          end
          target_ref_id = ngr[:node_id]
          target_ref_attrs.each do |attr|
            create_rows << attr.merge(:node_node_id => target_ref_id)
          end
        end
        attr_mh = node_groups.first.model_handle.create_childMH(:attribute)

        # TODO: see why below is not working and need to iterate over attributes names when calling Model.create_from_rows
        #Model.create_from_rows(attr_mh,create_rows,:convert => true)
        ndx_create_rows = Hash.new
        create_rows.each do |r|
          ndx = r[:display_name]
          (ndx_create_rows[ndx] ||= Array.new) << r
        end
        ndx_create_rows.values.each{|rows| Model.create_from_rows(attr_mh,rows,:convert => true)}
        nil
      end

      # node_instance and target_ref can be ids or be uri paths
      def self.target_ref_link_hash(node_instance,target_ref)
        hash = Link.attr_asignment(:node_group_id,node_instance).merge(Link.attr_asignment(:node_id,target_ref))
        {Link.ref(node_instance,target_ref) => hash}
      end
      module Link
        def self.attr_asignment(attr_name,val)
          {(val.kind_of?(Fixnum) ? attr_name.to_s : "*#{attr_name}") => val}
        end
        def self.ref(node_instance,target_ref)
          "#{target_ref.to_s}--#{node_instance.to_s}"
        end
      end
      
      class Element 
        include ElementMixin
        attr_reader :node,:num_needed
        def initialize(node_info)
          @node = node_info[:node]
          @num_needed = node_info[:num_needed]
          @type = :base_node_link
        end

        def add_target_ref_and_ngr!(ret,target,assembly)
          target_ref_hash = target_ref_hash(target,assembly)
          unless target_ref_hash.empty?
            (ret[:node] ||= Hash.new).merge!(target_ref_hash)
            node_group_rel_hash = target_ref_hash.keys.inject(Hash.new) do |h,node_ref|
              h.merge(BaseNodes.target_ref_link_hash(@node.id,"/node/#{node_ref}"))
            end
            (ret[:node_group_relation] ||= Hash.new).merge!(node_group_rel_hash)
          end
          ret
        end

        def target_ref_hash(target,assembly)
          ret = Hash.new
          unless display_name = @node.get_field?(:display_name)
            raise Error.new("Unexpected that that node has no name field")
          end
          external_ref = @node.external_ref
          unless external_ref.references_image?(target)
#            raise ErrorUsage.new("Node (#{display_name}) is not in target that supports node creation or does not have needed info")
            Log.error("Think this needs to be further contrsinaed: Node (#{display_name}) is not in target that supports node creation or does not have needed info")
          end
          (1..@num_needed).inject(Hash.new) do |h,index|
            hash = {
              :display_name => ret_display_name(display_name,:index => index,:assembly => assembly),
              :os_type => @node.get_field?(:os_type),
              :type => TargetRef.type(),
              :external_ref => external_ref.hash() 
            }          
            ref = ret_ref(display_name,:index => index,:assembly => assembly)
            h.merge(ref => hash)
          end
        end
      end
    end
  end
end; end; end
