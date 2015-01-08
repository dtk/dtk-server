#TODO: this needs to be synced with DTK::UpdateModule::Output
module DTK; class BaseModule
  class UpdateModule               
    class ExternalDependencies < Hash
      def initialize(hash={})
        unless (bad_keys = hash.keys - LegalKeys).empty?
          raise Error.new("Bad keys: #{bad_keys.join(',')}")
        end
        super()
        replace(hash)
      end
      KeysProblems = [:inconsistent,:possibly_missing,:ambiguous]
      KeysOk = [:ndx_matching_branches]
      LegalKeys = KeysProblems+KeysOk

      # TODO: maybe useful to make a hash with keys below a return class since used in different places in 
      # update_module

      # returns the following keys if they are non null
      # :external_dependencies
      # :ambiguous
      # :possibly_missing
      # :matching_module_refs
      def ret_hash_info()
        ret = Hash.new
        # TODO: a little confusing this is caused :external_dependencies; it is really possible problems
        set_if_not_nil!(ret,:external_dependencies,possible_problems?())
        set_if_not_nil!(ret,:ambiguous,self[:ambiguous])
        set_if_not_nil!(ret,:possibly_missing,self[:possibly_missing])
        set_if_not_nil!(ret,:matching_module_refs,component_module_refs?())
        ret
      end
     private
      def set_if_not_nil!(ret,key,val)
        ret.merge!(key => val) unless val.nil?
      end

      def possible_problems?()
        ret = Aux.hash_subset(self,KeysProblems)
        ret.reject!{|k,v|v.kind_of?(Array) and v.empty?}
        ret unless ret.empty? 
      end
      def component_module_refs?()
        ret = nil
        unless ndx_matching_branches = self[:ndx_matching_branches]
          return ret
        end
        ndx_ret = ndx_matching_branches.values.inject(Hash.new) do |h,r|
          h.merge(r.id() => r)
        end
        unless ndx_ret.empty?
          ComponentModuleRef.create_from_module_branches?(ndx_ret.values)
        end
      end
    end
  end              
end; end
