module XYZ
  class Datacenter < Model
#    set_relation_name(:datacenter,:datacenter)

    #######################
    ######### Model apis

    def get_items()
      objects = 
        get_objects_col_from_sp_hash({:columns => [:nodes]},:node) + 
        get_objects_col_from_sp_hash({:columns => [:node_groups]},:node_group) 
      objects.each{|o|o[:model_name] = o.model_name}
      add_ui_positions_if_needed!(objects)
    end
   private
    def add_ui_positions_if_needed!(objects)
      default_pos = DefaultPositions.new()
      objects.each do |o|
        o[:ui] ||= Hash.new
        pos = o[:ui][id().to_s.to_sym] ||= Hash.new
        pos[:left] ||= default_pos.ret_and_increment(o.model_name,:left)
        pos[:top] ||= default_pos.ret_and_increment(o.model_name,:top)
      end
    end
    class DefaultPositions
      def initialize()
        @positions = {
          :node => {:left => 200, :top => 100},
          :node_group => {:left => 100, :top => 100}
        }
      end
      def ret_and_increment(model_name,axis)
        ret = @positions[model_name][axis]
        @positions[model_name][axis] += Increment[model_name][axis]
        ret
      end
     private
      Increment = {
        :node => {:left => 50, :top => 50},
        :node_group => {:left => 50, :top => 50}
      }
    end

   public

    def self.get_links(id_handles)
      return Array.new if id_handles.empty?

#      id_handles = id_handles.map{|x|id_handle(x["id"].to_i,x["model"].to_sym)}

      node_id_handles = id_handles.select{|idh|idh[:model_name] == :node}
      if node_id_handles.size < id_handles.size
        models_not_treated = id_handles.reject{|idh|idh[:model_name] == :node}.map{idh|idh[:model_name]}.unique
        Log.error("Item list for Datacenter.get_port_links has models not treated (#{models_not_treated.join(",")}; they will be ignored")
      end

      raw_link_list = Node.get_port_links(node_id_handles)

      link_list = Array.new
      raw_link_list.each do |el|
        [:input_port_links,:output_port_links].each do |dir|
          (el[dir]||[]).each do |attr_link|
            port_dir = dir == :input_port_links ? "input" : "output"
            port_id = dir == :input_port_links ? attr_link[:input_id] : attr_link[:output_id]
            other_end_id = dir == :input_port_links ? attr_link[:output_id] : attr_link[:input_id]
            link_list << {
              :id => attr_link[:id],
              :item_id => el[:id],
              :item_name => el[:display_name],
              :port_id => port_id,
              :port_name => attr_link[:port_i18n],
              :type => attr_link[:type],
              :port_dir => port_dir,
              :hidden => attr_link[:hidden],
              :other_end_id => other_end_id
            }
          end
        end
      end
      link_list
    end

    #### clone helping functions
    def clone_post_copy_hook(clone_copy_output,opts={})
      case clone_copy_output.model_name()
       when :component 
        clone_post_copy_hook__component(clone_copy_output,opts)
       else #TODO: catchall taht will be expanded
        new_id_handle = clone_copy_output.id_handles.first
        StateChange.create_pending_change_item(:new_item => new_id_handle, :parent => id_handle())
      end
    end

   private

    def clone_post_copy_hook__component(clone_copy_output,opts)
      #TODO: right now this wil be just a composite component and clone_copy_output will be off form assembly - nodee - component
      #TODO: may put nodes under "install of assembly"
      level = 1
      node_idhs = clone_copy_output.children_id_handles(level,:node)
      node_new_items = node_idhs.map{|idh|{:new_item => idh, :parent => id_handle()}}
      return if node_new_items.empty?
      node_sc_idhs = StateChange.create_pending_change_items(node_new_items)

      indexed_node_info = Hash.new #TODO: may have state create this as output
      node_sc_idhs.each_with_index{|sc_idh,i|indexed_node_info[node_idhs[i].get_id()] = sc_idh}

      level = 2
      component_new_items = clone_copy_output.children_hash_form(level,:component).map do |child_hash| 
        {:new_item => child_hash[:id_handle], :parent => indexed_node_info[child_hash[:clone_parent_id]]}
      end
      return if component_new_items.empty?
      StateChange.create_pending_change_items(component_new_items)
    end

  end
end

