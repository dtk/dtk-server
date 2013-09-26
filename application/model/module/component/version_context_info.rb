module DTK
  class ComponentModule < Model
    class VersionContextInfo
      def self.get_in_hash_form(component_idhs,impl_idhs)
        #TODO: factor in sha info
        impls = Component::IncludeModule.get_version_context_info(component_idhs,impl_idhs)
pp [:VersionContextInfo,impls]
        impls.map{|impl|hash_form(impl)}
      end

     private
      def self.hash_form(impl,sha=nil)
        hash = impl.hash_form_subset(:repo,:branch,{:module_name=>:implementation})
        sha ? hsh.merge(:sha => sha) : hash
      end
    end
  end
end
