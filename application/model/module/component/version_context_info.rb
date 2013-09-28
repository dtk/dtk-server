module DTK
  class ComponentModule < Model
    class VersionContextInfo
      def self.get_in_hash_form(component_idhs,impl_idhs)
        impls = Component::IncludeModule.get_version_context_info(component_idhs,impl_idhs)
        sha_info = get_sha_indexed_by_impl(component_idhs)
        impls.map{|impl|convert_to_hash_form(impl,sha_info[impl[:id]])}
      end

     private
      def self.convert_to_hash_form(impl,sha=nil)
        hash = impl.hash_form_subset(:repo,:branch,{:module_name=>:implementation})
        sha ? hash.merge(:sha => sha) : hash
      end

      def self.get_sha_indexed_by_impl(component_idhs)
        ret = Hash.new
        return ret if component_idhs.empty?
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:locked_sha,:implementation_id],
          :filter => [:oneof,:id,component_idhs.map{|idh|idh.get_id()}]
        }
        Model.get_objs(component_idhs.first.createMH(),sp_hash).each do |r|
          if sha = r[:locked_sha]
            ret.merge!(r[:implementation_id] => sha)
          end
        end
        ret
        
      end
    end
  end
end
