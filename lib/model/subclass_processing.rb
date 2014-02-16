module DTK
  class Model
    module SubclassProcessingClassMixin
      def subclass_model(subclass_model_name,parent_model_name)
        class_eval("
          def get_objs(sp_hash,opts={})
            SubclassProcessing.new(self).get_objs(sp_hash,:#{subclass_model_name},opts)
          end"
         )
         class_eval("
           def self.get_objs(mh,sp_hash,opts={})
             if mh[:model_name] == :#{subclass_model_name}
               SubclassProcessing.get_objs(mh.createMH(:#{parent_model_name}),:#{subclass_model_name},sp_hash,opts)
             else
               super(mh,sp_hash,opts)
             end
           end"
         )
        SubclassProcessing.add_subclass_mapping(subclass_model_name,self)
        SubclassProcessing.add_model_name_mapping(self,subclass_model_name)
      end

     private    
      def models_to_add(model_name)
        SubclassProcessing.models_to_add(model_name)
      end

      def create_obj_optional_subclass(model_handle,hash_row,subclass_model_name=nil)
        unless id = hash_row[:id]
          raise Error.new("Hash (#{hash.inspect}) must have id key")
        end
        idh = model_handle.createIDH(:id => id)
        opts_model_name = (subclass_model_name ? {:model_name => subclass_model_name} : {})
        obj_with_just_id = idh.create_object(opts_model_name)
        obj_with_just_id.merge(hash_row)
      end
    end
    module SubclassProcessingMixin
      def create_subclass_obj(subclass_model_name)
        id_handle().create_object(:model_name => subclass_model_name).merge(self)
      end
    end

    class SubclassProcessing
      def initialize(model)
        @model = model
      end

      def self.get_objs(mh,subclass_model_name,sp_hash,opts={})
        Model.get_objs(mh,sp_hash,opts.merge(:subclass_model_name => subclass_model_name))
      end

      def get_objs(sp_hash,subclass_model_name,opts={})
        mh = @model.model_handle()
        Model.get_objs(mh,sp_hash,opts.merge(:model_handle => mh.createMH(subclass_model_name)))
      end

      def self.add_subclass_mapping(subclass_model_name,subclass_klass)
        @subclass_mapping ||= Hash.new
        @subclass_mapping[subclass_model_name] ||= subclass_klass
      end
      def self.models_to_add(model_name)
        ret = nil
        if ret = (@subclass_mapping||{})[model_name]
          return ret
        end
        #TODO: move over all models to use datadriven form       
        case model_name
          when :assembly then Assembly
          when :assembly_template then Assembly::Template
          when :assembly_instance then Assembly::Instance
          when :assembly_workspace then Workspace
          when :component_template then Component::Template
          when :component_instance then Component::Instance
          when :datacenter then Target
          when :node_group then NodeGroup
        end
      end


      def self.add_model_name_mapping(subclass_klass,model_name)
        @model_name_mapping ||= Hash.new
        @model_name_mapping[subclass_klass] ||= model_name
      end
      def self.model_name(model_class)
        if ret = (@model_name_mapping||{})[model_class]
          return ret
        end
        #TODO: move over all models to use datadriven form       
        case model_class
          when Component::Template then :component_template
          when Assembly::Instance then :assembly_instance
          when Assembly::Template then :assembly_template
          when NodeGroup then :node
        end
      end

      ##TODO: deprecate
      def self.add_parent_model_name_mapping(subclass_klass,parent_model_name)
        @parent_model_name_mapping ||= Hash.new
        @parent_model_name_mapping[subclass_klass] ||= parent_model_name
      end
      def self.parent_model_name(model_class)
        if ret = (@parent_model_name_mapping||{})[model_class]
          return ret
        end
        #TODO: move over all models to use datadriven form       
        case model_class
          when Component::Template then :component
          when Assembly::Instance then :component
          when Assembly::Template then :component
          when NodeGroup then :node
        end
      end
    end
  end
end
