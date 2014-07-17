module DTK; class ModuleDSL; class V3
  class ObjectModelForm; class Choice
    class LinkDefLink < self
      attr_reader :dependency_name
      attr_accessor :required
      def dep_cmp_ndx()
        @dep_cmp_name
      end
      def initialize(raw,dep_cmp_name,base_cmp)
        super(raw,dep_cmp_name,base_cmp)
        @dependency_name = nil
        @required = true
      end

      def convert(link_def_link,opts={})
        in_attr_mappings = link_def_link["attribute_mappings"]
        if (in_attr_mappings||[]).empty?
          err_msg = "The following link defs section on component '?1' is missing the attribute mappings section: ?2"
          raise ParsingError.new(err_msg,base_cmp_print_form(),{dep_cmp_print_form() => link_def_link})
        end

        unless type = opts[:link_type] || link_def_link_type(link_def_link)
          opts_collect_constants = Hash.new
          ret = [dup().convert(link_def_link,opts_collect_constants.merge!(:link_type => :external)).first,
                 dup().convert(link_def_link,opts_collect_constants.merge!(:link_type => :internal)).first]
          if constants = opts_collect_constants[:constants]
            opts.merge!(:constants => constants)
          end
          return ret
        end
        ret_info = {"type" => type.to_s}
        
        # TODO: pass in order from what is on dependency
        if order = opts[:order]||order(link_def_link)
          ret_info["order"] = order 
        end
        
        ret_info["attribute_mappings"] = in_attr_mappings.map{|in_am|convert_attribute_mapping(in_am,base_cmp(),dep_cmp(),opts)}
        
        set_single_possible_link!(dep_cmp(),ret_info)
        @dependency_name = link_def_link["dependency_name"]
        [self]
      end

    private
      def link_def_link_type(link_info)
        if loc = link_info["location"]
          case loc
          when "local" then "internal"
          when "remote" then "external"
          else raise ParsingError.new("Ill-formed dependency location type (?1)",loc)
          end
        end
      end

    end
  end; end
end; end; end
