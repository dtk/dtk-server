module DTK
  class Model
    module SubclassProcessingClassMixin
      def subclass_model(subclass_model_name,parent_model_name,opts={})
        class_eval("
          def get_objs(sp_hash,opts={})
           subclass_model_handle = model_handle(:#{subclass_model_name})
           super(sp_hash,opts.merge(:model_handle => subclass_model_handle))
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
         class_eval("
           def self.get_these_objs(mh,sp_hash,opts={})
             SubclassProcessing.get_objs(mh.createMH(:#{parent_model_name}),:#{subclass_model_name},sp_hash,opts)
           end"
         )
        SubclassProcessing.add_model_name_mapping(subclass_model_name,parent_model_name,self)
        SubclassProcessing.add_subclass_klass_mapping(self,subclass_model_name,opts)
      end

      # model_name could be concrete or subclass name
      def concrete_model_name(model_name)
        SubclassProcessing.concrete_model_name(model_name)||model_name
      end

      # TODO: cleanup
      def find_subtype_model_name(id_handle,opts={})
        model_name = id_handle[:model_name]
        return model_name unless SubclassProcessing.subclass_targets().include?(model_name)
        if shortcut = subclass_controllers(model_name,opts)
          return shortcut
        end
        case model_name
          when :component
           type = get_object_scalar_column(id_handle,:type)
           type == "composite" ? :assembly : model_name
          when :node
           type = get_object_scalar_column(id_handle,:type)
           %w{node_group_instance}.include?(type) ? :node_group : model_name
          when :target
           :target
          else
            Log.error("not implemented: finding subclass of relation #{model_name}")
            model_name
        end
      end

     private    
      # so can use calling cobntroller to shortcut needing datbase lookup
      def subclass_controllers(model_name,opts)
        if model_name == :node and opts[:controller_class] == Node_groupController 
          :node_group 
        elsif model_name == :component and opts[:controller_class] == AssemblyController
          :assembly
        end
      end

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
      def self.get_objs(mh,subclass_model_name,sp_hash,opts={})
        Model.get_objs(mh,sp_hash,opts.merge(:subclass_model_name => subclass_model_name))
      end

      def self.add_model_name_mapping(subclass_model_name,concrete_model_name,subclass_klass)
        @model_name_mapping ||= Hash.new
        @model_name_mapping[subclass_model_name] ||= {:concrete_model_name => concrete_model_name,:subclass_klass => subclass_klass}
      end
      def self.models_to_add(model_name)
        ret = nil
        if ret = model_name_info(model_name)[:subclass_klass]
          return ret
        end
        # TODO: move over all models to use data-driven form       
        case model_name
          when :assembly then Assembly
          when :assembly_template then Assembly::Template
          when :assembly_instance then Assembly::Instance
          when :assembly_workspace then Workspace
          when :component_template then Component::Template
          when :component_instance then Component::Instance
          when :datacenter then Target
          when :node_group then NodeGroup
          when :service_node_group then ServiceNodeGroup
          when :repo_with_branch then Repo::WithBranch
        end
      end

      def self.concrete_model_name(model_name)
        ret = nil
        if ret = model_name_info(model_name)[:concrete_model_name]
          return ret
        end
        HardCodedSubClassRelations[model_name]
      end
      def self.subclass_targets()
        @subclass_targets ||= (HardCodedSubClassRelations.values + @model_name_mapping.values.map{|r|r[:concrete_model_name]}).uniq
      end
      # TODO: move so that subclass_model generates these and get rid of HardCodedSubClassRelations
      HardCodedSubClassRelations = {
        :assembly           => :component,
        :assembly_workspace => :component,
        :component_template => :component,
        :component_instance => :component,
        :node_group         => :node,
        :service_node_group => :node
      }

      def self.add_subclass_klass_mapping(subclass_klass,model_name,opts={})
        @subclass_klass_mapping ||= Hash.new
        pntr = @subclass_klass_mapping[subclass_klass] ||= {:model_name => model_name}
        pntr[:print_form] ||= opts[:print_form] || default_print_form(model_name)
      end
      def self.model_name(model_class)
        if ret = subclass_klass_info(model_class)[:model_name]
          return ret
        end
        # TODO: move over all models to use data-driven form       
        if model_class == Component::Template then :component_template
        elsif model_class == Assembly::Instance then :assembly_instance
        elsif model_class == Assembly::Template then :assembly_template
        elsif model_class == NodeGroup then :node
        elsif model_class == ServiceNodeGroup then :node
        end
      end

      def self.print_form(model_class)
        if ret = subclass_klass_info(model_class)[:print_form]
          return ret
        end
        # TODO: move over all models to use data-driven form       
        if model_class == NodeGroup then 'node group'
        elsif model_class == Assembly::Instance then 'service'
        elsif model_class == Assembly::Template then 'service module'
        elsif model_class == Component::Template then 'component template'
        end
      end

     private
      def self.subclass_klass_info(model_class)
        (@subclass_klass_mapping||{})[model_class]||{}
      end
      def self.model_name_info(model_name)
        (@model_name_mapping||{})[model_name]||{}
      end

      def self.default_print_form(model_name)
        model_name.to_s.gsub(/_/,' ')
      end
    end
  end
end
