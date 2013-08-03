module DTK; class Task; class Template
  class ActionList
    class ConfigComponents < self
      def self.get(assembly,component_type=nil)
        opts = Hash.new
        if (component_type == :smoketest)
          opts.merge!(:filter_proc => lambda{|el|el[:basic_type] == "smoketest"}) 
        end
        assembly_cmps = assembly.get_component_list(:seed => new())
        ret = NodeGroup.get_component_list(assembly_cmps.map{|r|r[:node]},:add_on_to => assembly_cmps)
        ret.each_with_index{|r,i|r[:element_id] = i}
        ret
      end

      def indexed()
        Indexed.new(self)
      end

      class Indexed < SimpleHashObject
        def initialize(component_list)
          super()
          @component_id_info = Hash.new
          @ndx_by_node_id_cmp_type = Hash.new
          @cmp_model_handle = component_list.first && component_list.first.model_handle()

          component_list.each do |cmp|
            cmp_id = cmp[:id]
            node_id = cmp[:node][:id]
            (self[node_id] ||= Hash.new)[cmp_id] = cmp
            @component_id_info[cmp_id] ||= cmp.id_handle()
            pntr = @ndx_by_node_id_cmp_type[node_id] ||= Hash.new
            (pntr[cmp[:component_type]] ||= Array.new) << cmp
          end
        end

        def component_ids()
          @component_id_info.keys
        end
        def component_idhs()
          @component_id_info.values
        end
        
        def el(node_id,cmp_id)
          (self[node_id]||{})[cmp_id]
        end

        #block has params node_id, cmp_list_el
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


