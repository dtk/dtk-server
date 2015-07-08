module XYZ
  module AttrDepAnalaysisClassMixin
    # block params are attr_in,link,attr_out
    def dependency_analysis(aug_attr_list,&block)
      # find attributes that are required
      return if aug_attr_list.empty?
      attr_ids = aug_attr_list.map{|a|a[:id]}.uniq
      sp_hash = {
        cols: [:function,:index_map,:input_id,:output_id],
        filter: [:oneof ,:input_id, attr_ids]
      }
      sample_attr = aug_attr_list.first
      attr_link_mh = sample_attr.model_handle(:attribute_link)
      links_to_trace = get_objects_from_sp_hash(attr_link_mh,sp_hash)

      matches = []
      aug_attr_list.each do |attr|
        # ignore any node attribute
        next unless attr[:component]
        find_matching_links(attr,links_to_trace).each do |link|
          # attr is input attribute
          matches << {link: link, attr: attr}
        end
      end
      matches.each do |match|
        attr_in = match[:attr]
        link = match[:link]
        if attr_out = find_matching_output_attr(aug_attr_list,attr_in,link)
          block.call(attr_in,link,attr_out)
        end
      end
    end

    # block params is guard_rel which is hash with keys guard_attr,link,guarded_attr
    def guarded_attribute_rels(aug_attr_list,&block)
      Attribute.dependency_analysis(aug_attr_list) do |in_attr,link,out_attr|
        guard_rel = {
          guarded_attr: in_attr,
          guard_attr: out_attr,
          link: link
        }
        block.call(guard_rel) if GuardRel.needs_guard?(guard_rel)
      end
    end

    private

    def find_matching_output_attr(aug_attr_list,attr_in,link)
      # TODO: to make more efficient have other find_matching_output_attr__[link_fn]
      return find_matching_output_attr__eq_indexed(aug_attr_list,attr_in,link) if link[:function] == "eq_indexed"
      output_id =  link[:output_id]
      aug_attr_list.find do |attr|
        if attr[:id] == output_id
          case link[:function]
           when "eq" then true
           when "array_append" then true
           when "select_one"
            out_item_path = attr[:item_path]
            out_item_path && (attr_in[:item_path] == out_item_path[1,out_item_path.size-1])
           else
           Log.error("not treated when link function is #{link[:function]}")
            nil
          end
        end
      end
    end

    def find_matching_output_attr__eq_indexed(aug_attr_list,_attr_in,link)
      ret = nil
      if not (link[:index_map]||[]).size == 1
        Log.error("not treating index maps with multiple elements")
        return ret
      end
      link_output_index_map =  link[:index_map].first[:output]||[]
      output_id = link[:output_id]
      aug_attr_list.find do |attr|
        attr[:id] == output_id && matching_index_maps?(link_output_index_map,attr[:item_path])
      end
    end

    def matching_index_maps?(index_map,item_path)
      return true if index_map.empty?
      return nil unless index_map.size == item_path.size
      index_map.each_with_index do |el,i|
        return nil unless item_path[i] == (el.is_a?(String) ? el.to_sym : el)
      end
      true
    end

    def find_matching_links(attr,links)
      links.select{|link|link[:input_id] == attr[:id] && index_match(link,attr[:item_path])}
    end

    def index_match(link,item_path)
      ret = nil
      case link[:function]
       when "eq","array_append","select_one"
        ret = true
       when "eq_indexed"
        if (link[:index_map]||[]).size > 1
          Log.error("not treating index maps with multiple elements")
        end
        if index_map = ((link[:index_map]||[]).first||{})[:input]
          if item_path.is_a?(Array) && index_map.size == item_path.size
            item_path.each_with_index do |el,i|
              return nil unless el.to_s == index_map[i].to_s
            end
            ret = true
          end
        end
      end
      ret
    end

    module GuardRel
      def self.needs_guard?(guard_rel)
        guard_attr,guarded_attr,link = guard_rel[:guard_attr],guard_rel[:guarded_attr],guard_rel[:link]
        # guard_attr can be null if guard refers to node level attr
        # TODO: are there any other cases where it can be null; previous text said 'this can happen if guard attribute is in component that ran already'
        # TODO: below works if guard is node level attr
        return nil unless guard_attr

        # guarding attributes that are unset and are feed by dynamic attribute
        # TODO: should we assume that what gets here are only requierd attributes
        # TODO: removed clause (not guard_attr[:attribute_value]) in case has value that needs to be recomputed
        return nil unless guard_attr[:dynamic] && unset_guarded_attr?(guarded_attr,link)

        # TODO: clean up; not sure if still needed
        guard_task_type = (guard_attr[:semantic_type_summary] == "sap__l4" && (guard_attr[:item_path]||[]).include?(:host_address)) ? Task::Action::CreateNode : Task::Action::ConfigNode
        # right now only using config node to config node guards
        return nil if guard_task_type == Task::Action::CreateNode
        true
      end

      private

      # if dont know for certain better to err as being a guard
      def self.unset_guarded_attr?(guarded_attr,link)
        val = guarded_attr[:attribute_value]
        if val.nil?
          true
        elsif link[:function] == "array_append"
          unset_guarded_attr__array_append?(val,link)
        end
      end

      def self.unset_guarded_attr__array_append?(guarded_attr_val,link)
        if input_map = link[:index_map]
          unless input_map.size == 1
            raise Error.new("Not treating index map with more than one member")
          end
          input_index = input_map.first[:input]
          unless input_index.size == 1
            raise Error.new("Not treating input index with more than one member")
          end
          input_num = input_index.first
          unless input_num.is_a?(Fixnum)
            raise Error.new("Not treating input index that is non-numeric")
          end
          guarded_attr_val.is_a?(Array) && guarded_attr_val[input_num].nil?
        else
          true
        end
      end
    end
  end
end
