module DTK; class BaseModule
  module UpdateModule               
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
      
      def possible_problems?()
        ret = Aux.hash_subset(self,KeysProblems)
        ret unless ret.empty? 
      end
      
      def matching_module_branches?()
        if ndx_matching_branches = self[:ndx_matching_branches]
          ndx_ret = ndx_matching_branches.values.inject(Hash.new) do |h,r|
            h.merge(r.id() => r)
          end
          ndx_ret.values unless ndx_ret.empty?
        end
      end
    end
  end              
end; end
