module DTK
  class ChildContext
    class AssemblyComponentRef < self
      r8_nested_require('assembly_component_ref','add_on')
     private

      def initialize(clone_proc,hash)
        super
        find_component_templates_in_assembly!()
      end
      def clone_model_handle()
        model_handle().createMH(:component)
      end

      def find_component_templates_in_assembly!()
        merge!(:matches => get_aug_matching_component_refs())
      end

      #gets the component templates that each component ref is pointing to
      def get_aug_matching_component_refs()
        node_stub_ids = parent_rels.map{|pr|pr[:old_par_id]}
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:ref,:component_type,:version,:has_override_version,:component_template_id,:node_and_template_info,:template_id_synched],
          :filter => [:oneof, :node_node_id, node_stub_ids]
        }
        aug_cmp_refs = Model.get_objs(model_handle.createMH(:component_ref),sp_hash,:keep_ref_cols => true)

        module_constraints = @clone_proc.module_version_constraints()
        module_constraints.set_matching_component_template_info!(aug_cmp_refs)
      end

      def matching_component_refs__virtual_col()
        :component_template_id
      end

      #for processing component refs in an assembly
      def ret_new_objs_info(field_set_to_copy,create_override_attrs)
        #mapping from component ref to component template 
        component_mh = model_handle.createMH(:component)
        ndx_node_stub_to_instance = parent_rels.inject(Hash.new){|h,r|h.merge(r[:old_par_id] => r[:node_node_id])}
        ndx_node_template_to_ref = Hash.new

        cmps = matches.map{|m|component_mh.createIDH(:id => m[:component_template_id]).create_object()}
        ndx_component_templates = Component.find_ndx_workspace_templates(@clone_proc.project.id_handle(),cmps)

        mapping_rows = matches.map do |m|
          node = m[:node]
          old_par_id = node[:id]
          unless node_node_id = (parent_rels.find{|r|r[:old_par_id] == old_par_id}||{})[:node_node_id]
            raise Error.new("Cannot find old_par_id #{old_par_id.to_s} in parent_rels") 
          end
          component_template_id = ndx_component_templates[m[:component_template_id]][:id]
          #set  ndx_node_template_to_ref
          #first index is the associated node instance, second is teh component template
          pntr = ndx_node_template_to_ref[ndx_node_stub_to_instance[old_par_id]] ||= Hash.new 
          pntr[component_template_id] = m[:id]

          {:ancestor_id => component_template_id,
            :component_template_id =>  component_template_id,
            :node_node_id =>  node_node_id,
            :assembly_id => node[:assembly_id],
            :display_name => m[:display_name],
            :ref => m[:ref]
          }
        end

        mapping_ds = SQL::ArrayDataset.create(db(),mapping_rows,model_handle.createMH(:mapping))
      
        #all parent_rels will have same cols so taking a sample
        remove_cols = [:ancestor_id,:assembly_id,:display_name,:ref] + parent_rels.first.keys
        cmp_template_fs = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols({:id => :component_template_id})
        cmp_template_wc = nil
        cmp_template_ds = Model.get_objects_just_dataset(component_mh,cmp_template_wc,Model::FieldSet.opt(cmp_template_fs))

        select_ds = cmp_template_ds.join_table(:inner,mapping_ds,[:component_template_id])
        ret = Model.create_from_select(component_mh,field_set_to_copy,select_ds,create_override_attrs,aug_create_opts(create_opts))
        ret.each do |r|
          component_ref_id = ndx_node_template_to_ref[r[:node_node_id]][r[:ancestor_id]]
          raise Error.new("Variable component_ref_id should not be null") if component_ref_id.nil?
          r.merge!(:component_ref_id => component_ref_id, :component_template_id => r[:ancestor_id])
        end 
        ret
      end

      def aug_create_opts(create_opts)
        ret = create_opts
        if ret_sql_cols = create_opts[:returning_sql_cols]
          unless ret_sql_cols.include?(:component_type)
            ret = ret.merge(:returning_sql_cols => ret_sql_cols + [:component_type])
          end
        end
        ret
      end
 
   end
  end
end

