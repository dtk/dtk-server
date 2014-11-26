module DTK; class Clone
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

      # gets the component templates that each component ref is pointing to
      def get_aug_matching_component_refs()
        node_stub_ids = parent_rels.map{|pr|pr[:old_par_id]}
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:ref,:component_type,:version,:has_override_version,:component_template_id,:node_and_template_info,:template_id_synched],
          :filter => [:oneof, :node_node_id, node_stub_ids]
        }
        aug_cmp_refs = Model.get_objs(model_handle.createMH(:component_ref),sp_hash,:keep_ref_cols => true)

        component_module_refs = @clone_proc.component_module_refs()
        component_module_refs.set_matching_component_template_info?(aug_cmp_refs)
      end

      def matching_component_refs__virtual_col()
        :component_template_id
      end

      # for processing component refs in an assembly
      def ret_new_objs_info(field_set_to_copy,create_override_attrs)
        ret = Array.new
        # mapping from component ref to component template 
        component_mh = model_handle.createMH(:component)
        ndx_node_stub_to_instance = parent_rels.inject(Hash.new){|h,r|h.merge(r[:old_par_id] => r[:node_node_id])}
        ndx_to_find_cmp_ref_id = Hash.new

        cmp_mh = @clone_proc.project.model_handle(:component) 
        cmp_template_idhs = matches.map{|m|m[:component_template_id]}.uniq.map{|id|cmp_mh.createIDH(:id => id)}
        ndx_component_templates = Component::Template.get_info_for_clone(cmp_template_idhs).inject(Hash.new){|h,r|h.merge(r[:id]=>r)}
        
        mapping_rows = matches.map do |m|
          node = m[:node]
          old_par_id = node[:id]
          unless node_node_id = (parent_rels.find{|r|r[:old_par_id] == old_par_id}||{})[:node_node_id]
            raise Error.new("Cannot find old_par_id #{old_par_id.to_s} in parent_rels") 
          end
          component_template = ndx_component_templates[m[:component_template_id]]
          component_template_id = component_template[:id]

          # set  ndx_to_find_cmp_ref_id
          # first index is the associated node instance, second is teh component template
          pntr = ndx_to_find_cmp_ref_id[ndx_node_stub_to_instance[old_par_id]] ||= Hash.new 
          if pntr[m[:display_name]]
            Log.error("unexpected that multiple matches when creating ndx_to_find_cmp_ref_id")
          end
          pntr[m[:display_name]] = m[:id]

          {
            :ancestor_id => component_template_id,
            :component_template_id =>  component_template_id,
            :node_node_id =>  node_node_id,
            :assembly_id => node[:assembly_id],
            :locked_sha => component_template.get_current_sha!(),
            :display_name => m[:display_name],
            :ref => m[:ref]
          }
        end
        return ret if mapping_rows.empty?
 
        mapping_ds = array_dataset(mapping_rows,:mapping)
        # all parent_rels will have same cols so taking a sample
        remove_cols = [:ancestor_id,:assembly_id,:display_name,:ref,:locked_sha] + parent_rels.first.keys
        cmp_template_fs = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols({:id => :component_template_id})
        cmp_template_wc = nil
        cmp_template_ds = Model.get_objects_just_dataset(component_mh,cmp_template_wc,Model::FieldSet.opt(cmp_template_fs))

        select_ds = cmp_template_ds.join_table(:inner,mapping_ds,[:component_template_id])
        ret = Model.create_from_select(component_mh,field_set_to_copy,select_ds,create_override_attrs,aug_create_opts(create_opts))
        ret.each do |r|
          component_ref_id = ndx_to_find_cmp_ref_id[r[:node_node_id]][r[:display_name]]
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
end; end

