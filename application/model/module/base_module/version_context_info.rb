module DTK
  class BaseModule < Model
    module VersionContextInfo
      # returns a hash with keys: :repo,:branch,:implementation, :sha (optional)
      def self.get_in_hash_form(components,assembly_instance)
        impls = Component::IncludeModule.get_matching_implementations(assembly_instance,components.map{|r|r.id_handle()})
        sha_info = get_sha_indexed_by_impl(components)
        impls.map{|impl|hash_form(impl,sha_info[impl[:id]])}
      end

      private

      def self.hash_form(impl,sha=nil)
        hash = impl.hash_form_subset(:id,:repo,:branch,{module_name: :implementation})
        sha ? hash.merge(sha: sha) : hash
      end

      def self.get_sha_indexed_by_impl(components)
        ret = {}
        return ret if components.empty?
        sp_hash = {
          cols: [:id,:group_id,:display_name,:locked_sha,:implementation_id],
          filter: [:oneof,:id,components.map{|r|r.id()}]
        }
        Model.get_objs(components.first.model_handle(),sp_hash).each do |r|
          if sha = r[:locked_sha]
            ret.merge!(r[:implementation_id] => sha)
          end
        end
        ret
      end
    end
  end
end
