module DTK; class ModuleDSL; class V3
  class ObjectModelForm
    class LinkDef < OMFBase
      def self.ndx_link_def_links(in_link_defs,base_cmp,opts={})
        ret = {}
        return ret unless in_link_defs
        convert_to_hash_form(in_link_defs) do |dep_cmp_name,link_def_links|
          link_def_links = [link_def_links] unless link_def_links.is_a?(Array)
          link_def_links = convert_link_def_links(dep_cmp_name,link_def_links,base_cmp,opts)
          link_def_links.each do |ldl|
            ndx = ldl.dependency_name || dep_cmp_name
            (ret[ndx] ||= []) << ldl
          end
        end
        ret
      end

      def self.link_defs?(spliced_ndx_link_def_links)
        ret = nil
        return ret if spliced_ndx_link_def_links.empty?
        spliced_ndx_link_def_links.inject([]) do |a,(link_def_type,link_def_links)|
          a + [link_def(link_def_type,link_def_links)]
        end
      end

      private

      def self.link_def(link_def_type,link_def_links)
        OutputHash.new(
          "type" => link_def_type,
          "required" =>  link_def_required?(link_def_links),
          "possible_links" => link_def_links.map(&:possible_link)
        )
      end

      def self.link_def_required?(link_def_links)
        ret = nil
        link_def_links.each do |ldl|
          if ret.nil?
            ret = ldl.required
          else
            if ret != ldl.required
              base_cmp = ldl.base_cmp_print_form
              dep_cmp = ldl.dep_cmp_print_form()
              Log.info("Ambiguous whether link_def to '#{dep_cmp}' is required or not for component '#{base_cmp}'; so assuming required==true")
              ret = true
            end
          end
        end
        ret
      end

      #------ begin: related to ndx_link_def_links
      def self.convert_link_def_links(dep_cmp_name,link_def_links,base_cmp,opts={})
        link_def_links.inject([]) do |a,link|
          unless link.is_a?(Hash)
            err_msg = "The following link defs section on component '?1' is ill-formed: ?2"
            raise ParsingError.new(err_msg,component_print_form(base_cmp),dep_cmp_name => link_def_links)
          end
          a + convert_link_def_link(link,dep_cmp_name,base_cmp,opts)
        end
      end

      def self.convert_link_def_link(link_def_link,dep_cmp_name,base_cmp,opts={})
        Choice::LinkDefLink.new(link_def_link,dep_cmp_name,base_cmp).convert(link_def_link,opts)
      end
    end
  end
end; end; end
