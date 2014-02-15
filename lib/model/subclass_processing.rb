module DTK
  class Model
    module SubclassProcessingClassMixin
      def subclass_model(subclass_model_name,parent_model_name)
        class_eval("
          def get_objs(sp_hash,opts={})
            get_objs_subclass_model(sp_hash,:#{subclass_model_name},opts)
          end"
         )
         class_eval("
           def self.get_objs(mh,sp_hash,opts={})
             if mh[:model_name] == :#{subclass_model_name}
               get_objs_subclass_model(mh.createMH(:#{parent_model_name}),:#{subclass_model_name},sp_hash,opts)
             else
               super(mh,sp_hash,opts)
             end
           end"
         )
      end    
    end
  end
end
