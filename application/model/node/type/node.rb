module DTK; class Node
  class Type
    class Node < self
      Types = 
        [
         :stub,              # - in an assembly template
         :image,             # - corresponds to an IAAS, hyperviser or container image
         :instance,          # - in a service instance where it correspond to an actual node
         :staged,            # - in a service instance before actual node correspond to it
         :target_ref,        # - target_ref to actual node
         :target_ref_staged, # - target_ref to node not created yet
         :physical           # - target_ref that corresponds to a physical node   
        ]
      Types.each do |type|
        class_eval("def self.#{type}(); '#{type}'; end")
      end
      def self.types()
        Types
      end
    end
  end
end; end
