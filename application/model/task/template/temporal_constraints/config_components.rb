module DTK; class Task; class Template
  class TemporalConstraints
    class ConfigComponents < self
      def self.get(assembly,cmp_action_list)
        ret = new()
        return ret if cmp_action_list.empty?

        # indexed by [node_id][:cmp_id]
        ndx_cmp_list = Indexed.new(cmp_action_list)

        # ordering constraint come from teh following sources
        # dynamic attributes
        # port links with temporal order set
        # intra_node rels - (from the component_order and dependency rels)
        get_from_port_links(assembly,ndx_cmp_list) +
        get_from_dynamic_attribute_rel(ndx_cmp_list) +
        get_intra_node_rels(ndx_cmp_list)
      end

      private

      def self.get_from_port_links(assembly,ndx_cmp_list)
        ret = new()
        ordered_port_links = assembly.get_port_links(filter: [:neq,:temporal_order,nil])
        return ret if ordered_port_links.empty?
        sp_hash = {
          cols: [:ports,:temporal_order],
          filter: [:oneof, :id, ordered_port_links.map{|r|r.id}]
        }

        aug_port_links = Model.get_objs(assembly.model_handle(:port_link),sp_hash)
        aug_port_links.map do |pl|
          before_port = pl[DirField[pl[:temporal_order].to_sym][:before_field]]
          after_port = pl[DirField[pl[:temporal_order].to_sym][:after_field]]
          before_cmp_list_el = ndx_cmp_list.el(before_port[:node_node_id],before_port[:component_id])
          after_cmp_list_el = ndx_cmp_list.el(after_port[:node_node_id],after_port[:component_id])
          if constraint = create_temporal_constraint?(:port_link_order,before_cmp_list_el,after_cmp_list_el)
            ret << constraint
          end
        end
        ret
      end
      DirField = {
        before: {before_field: :input_port,  after_field: :output_port},  
        after: {before_field: :output_port, after_field: :input_port}  
      }

      def self.get_from_dynamic_attribute_rel(ndx_cmp_list)
        ret = new()
        attr_mh = ndx_cmp_list.model_handle(:attribute)
        filter = [:oneof,:component_component_id,ndx_cmp_list.component_ids]
        # shortcut if no dynamic attributes
        sp_hash = {
          cols: [:id],
          filter: [:and, [:eq,:dynamic,true], filter]
        }
        return ret if Model.get_objs(attr_mh,sp_hash).empty?

        # get augmented attr list, needed for dependency analysis
        aug_attr_list = Attribute.get_augmented(attr_mh,filter)
        Attribute.guarded_attribute_rels(aug_attr_list) do |guard_rel|
          guard_attr = guard_rel[:guard_attr]
          guarded_attr = guard_rel[:guarded_attr]
          before_cmp_list_el = ndx_cmp_list.el(guard_attr[:node][:id],guard_attr[:component][:id])
          after_cmp_list_el = ndx_cmp_list.el(guarded_attr[:node][:id],guarded_attr[:component][:id])
          if constraint = create_temporal_constraint?(:dynamic_attribute,before_cmp_list_el,after_cmp_list_el)
            ret << constraint
          end
        end
        ret
      end

      def self.get_intra_node_rels(ndx_cmp_list)
        ret = new()
        # TODO: more efficient way to do this; right now just leevraging existing methods; also these methods draw these relationships from 
        # component templates, not component instances
        cmp_deps = Component::Instance.get_ndx_intra_node_rels(ndx_cmp_list.component_idhs())
        cmp_deps.reject!{|_cmp_id,info|info[:component_dependencies].empty?}
        return ret if cmp_deps.empty?
        
        # component dependencies just have component type;
        # TODO: may extend so that it can match on title
        cmp_deps.each do |cmp_id,dep_info|
          ndx_cmp_list.els(cmp_id) do |node_id,after_cmp_list_el|
            dep_info[:component_dependencies].each do |before_cmp_type|
              ndx_cmp_list.index_by_node_id_cmp_type(node_id,before_cmp_type).each do |before_cmp_list_el|
                if constraint = create_temporal_constraint?(:intra_node,before_cmp_list_el,after_cmp_list_el)
                  ret << constraint
                end
              end
            end
          end
        end
        ret
      end

      def self.create_temporal_constraint?(type,before_cmp_list_el,after_cmp_list_el)
        if before_cmp_list_el && after_cmp_list_el
          klass = 
            case type 
            when :intra_node then TCBase()::IntraNode
            when :port_link_order then TCBase()::PortLinkOrder
            when :dynamic_attribute then TCBase()::DynamicAttribute
            end 
          klass.new(before_cmp_list_el,after_cmp_list_el) if klass
        end
      end

      def self.TCBase
        TemporalConstraint::ConfigComponent
      end

      class Indexed < SimpleHashObject
        def initialize(component_list)
          super()
          @component_id_info = {}
          @ndx_by_node_id_cmp_type = {}
          @cmp_model_handle = component_list.first && component_list.first.model_handle()

          component_list.each do |cmp|
            cmp_id = cmp[:id]
            node_id = cmp[:node][:id]
            (self[node_id] ||= {})[cmp_id] = cmp
            @component_id_info[cmp_id] ||= cmp.id_handle()
            pntr = @ndx_by_node_id_cmp_type[node_id] ||= {}
            (pntr[cmp[:component_type]] ||= []) << cmp
          end
        end

        def component_ids
          @component_id_info.keys
        end

        def component_idhs
          @component_id_info.values
        end
        
        def el(node_id,cmp_id)
          (self[node_id]||{})[cmp_id]
        end

        # block has params node_id, cmp_list_el
        def els(cmp_id,&block)
          each_pair do |node_id,ndx_by_cmp|
            if cmp_list_el = ndx_by_cmp[cmp_id]
              block.call(node_id,cmp_list_el)
            end
          end
        end

        def index_by_node_id_cmp_type(node_id,cmp_type)
          (@ndx_by_node_id_cmp_type[node_id]||{})[cmp_type]||[]
        end

        def model_handle(model_name)
          @cmp_model_handle && @cmp_model_handle.createMH(model_name)
        end
      end
    end
  end
end; end; end

