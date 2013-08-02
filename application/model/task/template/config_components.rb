module DTK; class Task; class Template
  class ConfigComponents < self
    def self.generate(assembly,component_type=nil)
      ret = create_stub(assembly.model_handle(:task_template))
      cmp_list = ComponentList.get(assembly,component_type)
      pp [:cmp_list,cmp_list]
      #indexed by [node_id][:cmp_id]
      ndx_cmp_list = cmp_list.indexed
      cmp_order_constraints = TemporalConstraints.get(assembly,ndx_cmp_list)
      #pp [:cmp_order_constraints,cmp_order_constraints]
      ret
    end

    class TemporalConstraint
      def initialize(type,before_cmp_list_el,after_cmp_list_el)
        @type = type
        @before_cmp_list_el = before_cmp_list_el
        @after_cmp_list_el = after_cmp_list_el
      end
      def self.create?(type,before_cmp_list_el,after_cmp_list_el)
        if before_cmp_list_el and after_cmp_list_el
          new(type,before_cmp_list_el,after_cmp_list_el)
        end
      end
    end

    module TemporalConstraints
      def self.get(assembly,ndx_cmp_list)
        ret = Array.new
        #ordering constrainst come from teh following sources
        # dynamic attributes
        # port links with temporal order set
        # component_ordering link def setting
        # component dependencies
        pp [:get_from_port_links,get_from_port_links(assembly,ndx_cmp_list)]
        pp [:get_from_dynamic_attribute_rel,get_from_dynamic_attribute_rel(ndx_cmp_list)]
        ret
      end
     private
      def self.get_from_port_links(assembly,ndx_cmp_list)
        ret = Array.new
        ordered_port_links = assembly.get_port_links(:filter => [:neq,:temporal_order,nil])
        return ret if ordered_port_links.empty?
        sp_hash = {
          :cols => [:ports,:temporal_order],
          :filter => [:oneof, :id, ordered_port_links.map{|r|r.id}]
        }

        aug_port_links = Model.get_objs(assembly.model_handle(:port_link),sp_hash)
        aug_port_links.map do |pl|
          before_port = pl[DirField[pl[:temporal_order].to_sym][:before_field]]
          after_port = pl[DirField[pl[:temporal_order].to_sym][:after_field]]
          before_cmp_list_el = ndx_cmp_list.el(before_port[:node_node_id],before_port[:component_id])
          after_cmp_list_el = ndx_cmp_list.el(after_port[:node_node_id],after_port[:component_id])
            TemporalConstraint.create?(:port_link_order,before_cmp_list_el,after_cmp_list_el)
        end.compact
      end
      DirField = {
        :before => {:before_field => :input_port,  :after_field => :output_port},  
        :after =>  {:before_field => :output_port, :after_field => :input_port}  
      }

      def self.get_from_dynamic_attribute_rel(ndx_cmp_list)
        ret = Array.new
        attr_mh = ndx_cmp_list.model_handle(:attribute)
        filter = [:oneof,:component_component_id,ndx_cmp_list.component_ids]
        #shortcut if no dynamic attributes
        sp_hash = {
          :cols => [:id],
          :filter => [:and, [:eq,:dynamic,true], filter]
        }
        return ret if Model.get_objs(attr_mh,sp_hash).empty?

        #get augmented attr list, needed for dependency analysis
        aug_attr_list = Attribute.get_augmented(attr_mh,filter)
        Attribute.guarded_attribute_rels(aug_attr_list) do |guard_rel|
          guard_attr = guard_rel[:guard_attr]
          guarded_attr = guard_rel[:guarded_attr]
          before_cmp_list_el = ndx_cmp_list.el(guard_attr[:node][:id],guard_attr[:component][:id])
          after_cmp_list_el = ndx_cmp_list.el(guarded_attr[:node][:id],guarded_attr[:component][:id])
          if temporal_constraint = TemporalConstraint.create?(:dynamic_attribute_rel,before_cmp_list_el,after_cmp_list_el)
            ret << temporal_constraint
          end
        end
        ret
      end
    end
    
    class ComponentList < Array
      def self.get(assembly,component_type=nil)
        opts = Hash.new
        if (component_type == :smoketest)
          opts.merge!(:filter_proc => lambda{|el|el[:basic_type] == "smoketest"}) 
        end
        assembly_cmps = assembly.get_component_list(:seed => ComponentList.new())
        NodeGroup.get_component_list(assembly_cmps.map{|r|r[:node]},:add_on_to => assembly_cmps)
      end

      def indexed()
        Indexed.new(self)
      end

      class Indexed < SimpleHashObject
        def initialize(component_list)
          super()
          @component_ids = component_list.map{|cmp|cmp[:id]}.uniq
          @cmp_model_handle = component_list.first && component_list.first.model_handle()
          component_list.each do |r|
            node_id = r[:node][:id]
            cmp_id = r[:id]
            (self[node_id] ||= Hash.new)[cmp_id] = r
          end
        end

        attr_reader :component_ids
        
        def el(node_id,cmp_id)
          (self[node_id]||{})[cmp_id]
        end

        def model_handle(model_name)
          @cmp_model_handle && @cmp_model_handle.createMH(model_name)
        end
        
      end
    end
  end
end; end; end

