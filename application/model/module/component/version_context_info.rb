module DTK
  class ComponentModule < Model
    class VersionContextInfo
      def self.get_in_hash_form(component_idhs,impl_idhs)
        impls = Component::IncludeModule.get_version_context_info(component_idhs,impl_idhs)
        sha_info = get_sha_indexed_by_impl(component_idhs)
        impls.map{|impl|convert_to_hash_form(impl,sha_info[impl[:id]])}
      end
      def self.get_in_hash_form_from_templates(component_templates)
        impl_idhs = get_implementation_idhs(component_templates)
        get_in_hash_form(component_templates.map{|cmp|cmp.id_handle()},impl_idhs)
      end

     private
      def self.get_implementation_idhs(component_templates)
        ret = Array.new
        if component_templates.empty?
          return ret
        end
        impl_mh = component_templates.first.model_handle(:implementation)
        #not efficient way to get implementation_id, but this is only needed if calling fn does not fill in this field
        component_templates.map do |cmp_template|
          if impl_id =  cmp_template.get_field?(:implementation_id)
            impl_mh.createIDH(:id => impl_id)
          else
            Log.error("Unexpected that implementation_id is nil")
            nil
          end
        end.compact
      end

      def self.convert_to_hash_form(impl,sha=nil)
        hash = impl.hash_form_subset(:id,:repo,:branch,{:module_name=>:implementation})
        sha ? hash.merge(:sha => sha) : hash
      end

      def self.get_sha_indexed_by_impl(component_idhs)
        ret = Hash.new
        return ret if component_idhs.empty?
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:locked_sha,:implementation_id],
          :filter => [:oneof,:id,component_idhs.map{|idh|idh.get_id()}]
        }
        Model.get_objs(component_idhs.first.createMH(),sp_hash).each do |rt|
          if sha = rt[:locked_sha]
            ret.merge!(rt[:implementation_id] => sha)
          end
        end
        ret
      end
    end
  end
end
