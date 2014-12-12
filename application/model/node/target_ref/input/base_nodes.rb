module DTK; class Node; class TargetRef
  class Input 
    class BaseNodes < self
      r8_nested_require('base_nodes','element')

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
        # TODO: can be more efficienct and avoid calling below if create_linked_target_refs? finds as opposed to creates
        # target refs
        move_node_attributes_to_target_refs(target,[{:node_instance => node,:target_ref => target_ref}])
        target_ref
      end

      # TODO: need better name for create_linked_target_ref? vs create_linked_target_refs?
      # since different in what they do with node attributes

      # This creates if needed target refs and links nodes to them
      # returns new idhs indexed by node (id) they linked to
      # or if they exist their idhs
      # for any node that is node group, this copies the node group's attributes to the target refs
      def self.create_linked_target_refs?(target,assembly,nodes,opts={})
        ret = Hash.new
        return ret if nodes.empty?
        ndx_target_ref_idhs = TargetRef.ndx_matching_target_ref_idhs(:node_instance_idhs => nodes.map{|n|n.id_handle})

        create_objs_hash = Hash.new
        nodes.each do |node|
          node_id = node[:id]
          cardinality = opts[:new_cardinality]||node.attribute.cardinality
          target_ref_idhs = ndx_target_ref_idhs[node_id]||[]
          num_existing = target_ref_idhs.size
          num_needed = cardinality - num_existing
          if num_needed > 0
            el = Element.new(:node => node,:num_needed => num_needed,:offset => num_existing+1)
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
          # copy from node group to target refs 
          copy_node_attributes?(target,nodes,ngr_idhs)
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
      # TODO: Step in fixing DTK-1739 is putting in this copy to possible replace above Not switching over yet
      # in create_linked_target_ref? in master branch until make sure that this does not impact node groups
      # to_link_array is of form [{:node_instance => node,:target_ref => target_ref},..]
      def self.copy_node_attributes_to_target_refs(target,to_link_array)
        return if to_link_array.empty?
        cols = Model::FieldSet.all_real(:attribute).with_removed_cols(:id,:local_id).cols
        sp_hash = {
          :cols => cols,
          :filter => [:oneof,:node_node_id,to_link_array.map{|n|n[:node_instance].id()}]
        }
        attr_mh = target.model_handle(:node).create_childMH(:attribute)
        attrs = Model.get_objs(attr_mh,sp_hash,:keep_ref_cols => true)
        return if attrs.empty?
        to_link_hash = to_link_array.inject(Hash.new){|h,r|h.merge(r[:node_instance].id => r[:target_ref].id)}

        create_rows = attrs.map do |a|
          target_ref_id = to_link_hash[a[:node_node_id]]
          el = Hash.new
          # copy with some special processing
          a.each do |k,v|
            if k == :id
              #dont copy
            elsif k == :node_node_id
              el.merge!(k => target_ref_id)
            elsif v.nil?
              #dont copy
            else
              el.merge!(k => v)
            end
          end
          el
        end
        Model.create_from_rows(attr_mh,create_rows,:convert => true)
      end

      # copy node attributes from node group to target refs 
      def self.copy_node_attributes?(target,nodes,ngr_idhs)
        node_groups = nodes.select{|n|n.is_node_group?()}
        return if node_groups.empty?
        
        ng_idhs = node_groups.map{|ng|ng.id_handle()}
        ndx_ng_target_ref_attrs = Hash.new
        ServiceNodeGroup.get_node_attributes_to_copy(ng_idhs).each do |ng_attr|
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
          :cols => [:node_group_id,:target_ref],
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
          add_target_ref_attrs!(create_rows,ngr[:target_ref],target_ref_attrs)
        end
        attr_mh = node_groups.first.model_handle.create_childMH(:attribute)
        ndx_create_rows = Hash.new
        create_rows.each do |r|
          ndx = r[:display_name]
          (ndx_create_rows[ndx] ||= Array.new) << r
        end
        ndx_create_rows.values.each{|rows| Model.create_from_rows(attr_mh,rows,:convert => true)}
        nil
      end

      def self.add_target_ref_attrs!(create_rows,target_ref,target_ref_attrs)
        target_ref_id = target_ref.id
        target_ref_attrs.each do |attr|
          attr = attr.merge(:node_node_id => target_ref_id)
          # any special processing for :value_asserted or :value_derived
          case attr[:display_name]
            when 'name'
              # gsub is to strip off leading assembly name (if present)
              attr[:value_asserted] = target_ref[:display_name].gsub(/^.+::/,'') 
          end
          create_rows << attr 
        end
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
      
    end
  end
end; end; end
