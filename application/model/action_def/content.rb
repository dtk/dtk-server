module DTK; class ActionDef
 class Content < Hash
   def initialize(hash_content)
     super()
     # TODO: stub; will walk hash substructure and will replace with sub objects
     replace(hash_content)
   end
 end
end; end
