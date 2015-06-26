module XYZ
  class Library < Model
    ### get methods

    def get_node_binding_rulesets(filter=nil)
      full_filter = [:eq,:library_library_id,id()]
      if filter 
        full_filter = [:and,full_filter,filter]
      end
      sp_hash = {
        :cols => [:id,:group_id,:ref],
        :filter => full_filter
      }
      Model.get_objs(model_handle(:node_binding_ruleset),sp_hash,:keep_ref_cols => true)
    end

    ### end: get methods

    class << self 
      def create_users_private_library?(model_handle)
        user_obj = CurrentSession.new.get_user_object()
        private_group_obj = user_obj.get_private_group()
        library_mh = model_handle.createMH(:model_name => :library, :group_id => private_group_obj[:id])
        username = user_obj[:username]
        ref = users_private_library_ref(username)
        lib_name = users_private_library_name(username)
        Model.create_from_row?(library_mh,ref,{:display_name => lib_name})
      end

      def create_public_library?(model_handle)
        ref = lib_name = public_library_name()
        Model.create_from_row?(model_handle,ref,{:display_name => lib_name})
      end

      def get_users_private_library(model_handle,username=nil)
        username ||=  CurrentSession.new.get_username()
        sp_hash = {
          :cols => [:id,:display_name,:group_id],
          :filter => [:eq,:display_name,users_private_library_name(username)] 
        }
        get_obj(model_handle,sp_hash)
      end

      def get_public_library(model_handle)
        sp_hash = {
          :cols => [:id,:display_name,:group_id],
          :filter => [:eq,:display_name,public_library_name()]
        }
        get_obj(model_handle,sp_hash)
      end

      def check_valid_id(model_handle,id)
        check_valid_id_default(model_handle,id)
      end

      def name_to_id(model_handle,name)
        name_to_id_default(model_handle,name)
      end

     private
      def users_private_library_name(username)
        "private"
      end
      def users_private_library_ref(username)
        "private-#{username}"
      end

      def public_library_name()
        "public"
      end
    end

    def info_about(about,opts={})
      case about
       when :assemblies
        filter = [:eq, :library_library_id, id()]
        Assembly::Template.list(model_handle(:component),:filter => filter)
       when :nodes
        filter = [:eq, :library_library_id, id()]
        Node::Template.list(model_handle,:filter => filter)
      when :components
        raise Error.new("should not be reached")
        # Component::Template.list(model_handle,:library_idh => id_handle())
       else
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")        
      end.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

    def clone_post_copy_hook(clone_copy_output,opts={})
      new_id_handle = clone_copy_output.id_handles.first
      # TODO: hack; this should be optained from clone_copy_output
      new_assembly_obj = new_id_handle.create_object().update_object!(:display_name)
      case new_id_handle[:model_name]
       when :component then clear_dynamic_attributes(new_id_handle,opts)
      end
      level = 1
      node_hash_list = clone_copy_output.get_children_object_info(level,:node)
      unless node_hash_list.empty?
        node_mh = new_id_handle.createMH(:node)
        clone_post_copy_hook__child_nodes(node_mh,node_hash_list,new_assembly_obj) 
      end
    end
   private
    def clone_post_copy_hook__child_nodes(node_mh,node_hash_list,new_assembly_obj)
      rows = node_hash_list.map do |r|
        ext_ref = r[:external_ref] && r[:external_ref].reject{|k,v|k == :instance_id}.merge(:type => "ec2_image")
        update_row = {
          :id => r[:id],
          :external_ref =>  ext_ref,
          :operational_status => nil,
          :is_deployed => false
        }
        assembly_name = new_assembly_obj[:display_name]
        update_row[:display_name] = "#{assembly_name}-#{r[:display_name]}" if assembly_name and r[:display_name]
        update_row
      end
      Model.update_from_rows(node_mh,rows)
    end

    def clear_dynamic_attributes(new_id_handle,opts)
      attrs_to_clear = get_dynamic_attributes(:node,new_id_handle) + get_dynamic_attributes(:component,new_id_handle)
      Attribute.clear_dynamic_attributes_and_their_dependents(attrs_to_clear,:add_state_changes => false)
    end
   private
    # returns attributes that will be cleared
    def get_dynamic_attributes(model_name,new_id_handle)
      if model_name == :component
        col = :node_assembly_parts_cmp_attrs
      elsif model_name == :node
        col = :node_assembly_parts_node_attrs
      else
        raise Error.new("unexpected model_name #{model_name}")
      end
      sp_hash = {
        :filter => [:and,[:eq, :id, new_id_handle.get_id()],[:eq, :type, "composite"]],
        :columns => [col]
      }
      cmp_mh = new_id_handle.createMH(:component)
      Model.get_objs(cmp_mh,sp_hash).map do |r|
        attr = r[:attribute]
        attr if attr[:dynamic]
      end.compact
    end
  end
end
