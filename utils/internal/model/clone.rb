#TODO: this needs much cleanup: may spearete into parts fro assemblies and then teh rest which is containment based copying
#TODO: try to move more to chidl context geenraizing to be object context and possibly using it to subsume cloneprocesseor
r8_nested_require('clone','global')
r8_nested_require('clone','child_context')
r8_nested_require('clone','foreign_key_info')
module XYZ
  module CloneClassMixins
    #TODO: may just be temporary; this function takes into account that front end may not send teh actual target handle for componenst who parents
    # are on components not nodes
    def find_real_target_id_handle(id_handle,specified_target_idh)
      return specified_target_idh unless id_handle[:model_name] == :component and specified_target_idh[:model_name] == :node
      id_handle.create_object().determine_cloned_components_parent(specified_target_idh)
    end
  end

  module CloneInstanceMixins
    def clone_into(clone_source_object,override_attrs={},opts={})
      target_id_handle = id_handle_with_auth_info()
       ##constraints
      unless opts[:no_constraint_checking]
        if clone_source_object.class == Component and self.class == Node
          if constraints = clone_source_object.get_constraints!(:update_object => true)
            target = {"target_node_id_handle" => target_id_handle}
            constraint_opts = {:raise_error_when_error_violation => true, :update_object => clone_source_object}
            constraints.evaluate_given_target(target,constraint_opts)
          end
        end
      end

      clone_source_object.add_model_specific_override_attrs!(override_attrs,self)
      proc = CloneCopyProcessor.create(clone_source_object,opts.merge(:include_children => true))
      clone_copy_output = proc.clone_copy_top_level(clone_source_object.id_handle,[target_id_handle],override_attrs)
      new_id_handle = clone_copy_output.id_handles.first
      return nil unless new_id_handle
      #calling with respect to target
      clone_post_copy_hook(clone_copy_output,opts)

      if clone_source_object.class == Component and target_id_handle[:model_name] == :node
        Violation.update_violations([target_id_handle])
      end
      if opts[:ret_new_obj_with_cols]
        clone_copy_output.objects.first
      else
        new_id_handle.get_id()
      end
    end

    def clone_into_library_assembly(assembly_idh,id_handles)
      opts = {:include_children => true}
      proc = CloneCopyProcessor.create(assembly_idh.create_object(),opts)
      proc.add_id_handle(assembly_idh)

      #group id handles by model type
      ndx_id_handle_groups = Hash.new
      id_handles.each do |idh|
        model_name = idh[:model_name]
        (ndx_id_handle_groups[model_name] ||= Array.new) << idh
      end

      assembly_id_assign = {:assembly_id => assembly_idh.get_id()}
      overrides = assembly_id_assign.merge(:component => assembly_id_assign)
      ndx_id_handle_groups.each_value do |child_id_handles|
        child_context = proc.ret_child_context(child_id_handles,id_handle(),overrides)
        proc.clone_copy_child_objects(child_context)
      end

      proc.shift_foregn_keys()
      #TODO: check if clone_post copy needs to be done after key shift; if not can simplify
      clone_copy_output = proc.output
      clone_post_copy_hook(clone_copy_output)

      assembly_idh.get_id()
    end

    def get_constraints()
      get_constraints!()
    end

    #this gets optionally overwritten
    def source_clone_info_opts()
      {:ret_new_obj_with_cols => [:id]}
    end

   protected
    # to be optionally overwritten by object representing the source
    def add_model_specific_override_attrs!(override_attrs,target_obj)
    end

    # to be optionally overwritten by object representing the target
    def clone_post_copy_hook(clone_copy_output,opts={})
    end

    # to be overwritten
    #opts can be {:update_object => true} to update object
    def get_constraints!(opts={})
      nil
    end

    private
    #TODO: slight refactor of CloneCopyOutput so each child is of form {:parent => <parent>,:child => <CloneCopyOutput>}
    class CloneCopyOutput
      def initialize(source_obj,opts={})
        @source_object = source_obj
        @id_handles = Array.new
        @objects = nil
        @children = Hash.new
        #TODO: more efficient than making this Boolean is structure that indicates what depth to save children 
        @include_children = opts[:include_children]
        @ret_new_obj_with_cols = opts[:ret_new_obj_with_cols]
        end

      attr_reader :source_object, :id_handles, :ret_new_obj_with_cols, :objects
      def model_name()
        #all id handles wil be of same type
        @id_handles.first && @id_handles.first[:model_name]
      end

      def get_children_object_info(level,model_name)
        ((@children[level]||{})[model_name]||[]).map{|x|x[:obj_info]}
      end

      def children_hash_form(level,model_name)
        unless @include_children
          Log.error("children should not be called on object with @include_children set to false")
          return Array.new
        end
        (@children[level]||{})[model_name]||[]
      end

      def children_id_handles(level,model_name)
        children_hash_form(level,model_name).map{|child_hash|child_hash[:id_handle]}
      end

      def is_assembly?()
        #TODO: cleanup; this assumes that assembly call wil create an object
        objects and objects.first and objects.first.is_assembly?
      end

      def set_new_objects!(objs_info,target_mh)
        @id_handles = Model.ret_id_handles_from_create_returning_ids(target_mh,objs_info)
        if @ret_new_obj_with_cols
          @objects = Array.new
          objs_info.each_with_index do |obj_hash,i|
            obj = @id_handles[i].create_object()
            @ret_new_obj_with_cols.each{|col|obj[col] ||= obj_hash[col] if obj_hash.has_key?(col)}
            @objects << obj
          end
        end
        @id_handles
      end

      def add_id_handle(id_handle)
        @id_handles  << id_handle
      end

      def add_new_children_objects(objs_info,target_mh,parent_col,level)
        child_idhs = Model.ret_id_handles_from_create_returning_ids(target_mh,objs_info)
        return child_idhs unless @include_children
        level_p =  @children[level] ||= Hash.new
        objs_info.each_with_index do |child_obj,i|
          idh = child_idhs[i] 
          children = level_p[idh[:model_name]] ||= Array.new
          #clone_parent_id can differ from parent_id if for example node is under an assembly
          children << {:id_handle => idh, :clone_parent_id => child_obj[parent_col], :obj_info => child_obj}
        end
        child_idhs
      end
    end

    class CloneCopyProcessor
     private
      include ForeignKeyInfoMixin

      def get_nested_objects_top_level(model_handle,target_parent_mh,objs_info,recursive_override_attrs,opts={})
        ChildContext.get_from_parent_relation(self,model_handle,objs_info,recursive_override_attrs)
      end
    end

    class CloneCopyProcessorAssembly < CloneCopyProcessor
      private
      def get_nested_objects_top_level(model_handle,target_parent_mh,assembly_objs_info,recursive_override_attrs,opts={})
        raise Error.new("Not treating assembly_objs_info with more than 1 element") unless assembly_objs_info.size == 1
        assembly_obj_info = assembly_objs_info.first
        ancestor_id = assembly_obj_info[:ancestor_id]
        target_parent_mn = target_parent_mh[:model_name]
        model_name = model_handle[:model_name]
        new_assembly_assign = {:assembly_id => assembly_obj_info[:id]}
        new_par_assign = {DB.parent_field(target_parent_mn,model_name) => assembly_obj_info[:parent_id]}
        CloneGlobal::AssemblyChildren.map do |nested_model_name|
          #TODO: push this into ChildContext.create
          nested_mh = model_handle.createMH(:model_name => nested_model_name, :parent_model_name => target_parent_mn)
          override_attrs = new_assembly_assign.merge(ret_child_override_attrs(nested_mh,recursive_override_attrs))
          create_opts = {:duplicate_refs => :allow, :returning_sql_cols => [:ancestor_id,:assembly_id]}

          #putting in nulls to null-out; more efficient to omit this columns in create
          parent_rel = (DB_REL_DEF[nested_model_name][:many_to_one]||[]).inject({:old_par_id => ancestor_id}) do |hash,pos_par|
            hash.merge(Model.matching_models?(pos_par,target_parent_mn) ? new_par_assign : {DB.parent_field(pos_par,model_name) => SQL::ColRef.null_id})
          end
          if Model.matching_models?(nested_model_name,:node) 
            unless (override_attrs[:component]||{})[:assembly_id]
              override_attrs.merge!(:component => new_assembly_assign)
            end
          end
          target_idh = target_parent_mh.createIDH(:id => assembly_obj_info[:parent_id])
          ChildContext.create(self,{:model_handle => nested_mh, :clone_par_col => :assembly_id, :parent_rels => [parent_rel], :override_attrs => override_attrs, :create_opts => create_opts, :ancestor_id => ancestor_id, :target_idh => target_idh})
        end
      end
    end

    class CloneCopyProcessor
      def self.create(source_obj,opts={})
        if source_obj.is_assembly?
          CloneCopyProcessorAssembly.new(source_obj,opts)
        else
          new(source_obj,opts)
        end
      end

      def initialize(source_obj,opts={})
        @db = source_obj.class.db
        @fk_info = ForeignKeyInfo.new(@db)
        @model_name = source_obj.model_name()
        @ret = CloneCopyOutput.new(source_obj,opts)
      end
      private :initialize
      def output()
        @ret
      end

      def shift_foregn_keys()
        fk_info.shift_foregn_keys()
      end

      #copy part of clone
      #targets is a list of id_handles, each with same model_name 
      def clone_copy_top_level(source_id_handle,targets,recursive_override_attrs={})
        return @ret if targets.empty?

        source_model_name = source_id_handle[:model_name]
        source_model_handle = source_id_handle.createMH()
        source_parent_id_col = source_model_handle.parent_id_field_name()

        #all targets will have same model handle
        sample_target =  targets.first
        target_parent_mh = sample_target.createMH()
        target_mh = target_parent_mh.create_childMH(source_id_handle[:model_name])

        target_parent_id_col = target_mh.parent_id_field_name()
        targets_rows = targets.map{|id_handle|{target_parent_id_col => id_handle.get_id()}}
        targets_ds = SQL::ArrayDataset.create(db,targets_rows,ModelHandle.new(source_id_handle[:c],:target))

        source_wc = {:id => source_id_handle.get_id()}

        remove_cols = (source_parent_id_col == target_parent_id_col ? [:id,:local_id] : [:id,:local_id,source_parent_id_col])
        field_set_to_copy = Model::FieldSet.all_real(source_model_name).with_removed_cols(*remove_cols)
        fk_info.add_foreign_keys(source_model_handle,field_set_to_copy)
        source_fs = Model::FieldSet.opt(field_set_to_copy.with_removed_cols(target_parent_id_col))
        source_ds = Model.get_objects_just_dataset(source_model_handle,source_wc,source_fs)

        select_ds = targets_ds.join_table(:inner,source_ds)

        #process overrides
        override_attrs = ret_real_columns(source_model_handle,recursive_override_attrs)
        override_attrs = add_to_overrides_null_other_parents(override_attrs,target_mh[:model_name],target_parent_id_col)
        create_override_attrs = override_attrs.merge(:ancestor_id => source_id_handle.get_id()) 

        new_objs_info = Model.create_from_select(target_mh,field_set_to_copy,select_ds,create_override_attrs,create_opts_for_top())
        return @ret if new_objs_info.empty?
        new_id_handles = @ret.set_new_objects!(new_objs_info,target_mh)
        fk_info.add_id_mappings(source_model_handle,new_objs_info, :top => true)

        fk_info.add_id_handles(new_id_handles) #TODO: may be more efficient adding only id handles assciated with foreign keys

        #iterate over all nested objects which includes children object plus, for example, components for composite components
        get_nested_objects_top_level(source_model_handle,target_parent_mh,new_objs_info,recursive_override_attrs).each do |child_context|
          clone_copy_child_objects(child_context)
        end
        fk_info.shift_foregn_keys()
        @ret
      end

      def clone_copy_child_objects(child_context,level=1)
        child_context.clone_copy_child_objects(self,level)
        @ret
      end

      def add_new_children_objects(new_objs_info,child_model_handle,clone_par_col,level)
        @ret.add_new_children_objects(new_objs_info,child_model_handle,clone_par_col,level)
      end

      def add_to_overrides_null_other_parents(overrides,model_name,selected_par_id_col)
        many_to_one = DB_REL_DEF[model_name][:many_to_one]||[]
        many_to_one.inject(overrides) do |ret_hash,par_mn|
          par_id_col = DB.parent_field(par_mn,model_name)
          if selected_par_id_col == par_id_col or overrides.has_key?(par_id_col)
            ret_hash
          else
            ret_hash.merge(par_id_col => SQL::ColRef.null_id)
          end
        end
      end

      def ret_child_context(id_handles,target_idh,existing_override_attrs={})
        #TODO: push this into ChildContext.create
        #assuming all id_handles have same model_handle
        sample_idh = id_handles.first
        model_name = sample_idh[:model_name]
        #so model_handle gets auth context from target_idh
        model_handle = target_idh.create_childMH(model_name)

        par_id_col = DB.parent_field(target_idh[:model_name],model_name)
        override_attrs = add_to_overrides_null_other_parents(existing_override_attrs,model_name,par_id_col)
        override_attrs.merge!(par_id_col => target_idh.get_id())

        ret_sql_cols = [:ancestor_id]
        case model_name
          when :node then ret_sql_cols << :external_ref
        end
        create_opts = {:duplicate_refs => :allow, :returning_sql_cols => ret_sql_cols}
        parent_rels = id_handles.map{|idh|{:old_par_id => idh.get_id()}}
        
        ChildContext.create(self,{:model_handle => model_handle, :clone_par_col => :id, :parent_rels => parent_rels, :override_attrs => override_attrs, :create_opts => create_opts})
      end

      def add_id_handle(id_handle)
        @ret.add_id_handle(id_handle)
      end

      def ret_child_override_attrs(child_model_handle,recursive_override_attrs)
        recursive_override_attrs[(child_model_handle[:model_name])]||{}
      end

      attr_reader :db,:fk_info, :model_name

      def ret_real_columns(model_handle,recursive_override_attrs)
        fs = Model::FieldSet.all_real(model_handle[:model_name])
        recursive_override_attrs.reject{|k,v| not fs.include_col?(k)}
      end

     private
      def create_opts_for_top()
        dups_allowed_for_cmp = true #TODO stub

        returning_sql_cols = [:ancestor_id] 
        #TODO" may make what are returning sql columns methods in model classes liek do for clone post copy
        case model_name
          when :component then returning_sql_cols << :type
        end

        (@ret.ret_new_obj_with_cols||{}).each{|col| returning_sql_cols << col unless returning_sql_cols.include?(col)}
        {:duplicate_refs => dups_allowed_for_cmp ? :allow : :prune_duplicates,:returning_sql_cols => returning_sql_cols}
      end

    end
  end
end
