module DTK; class ComponentDSL; class V3
  class ObjectModelForm
    class LinkDef < OMFBase
      def self.spliced_ndx_link_def_links(in_link_defs,base_cmp,ndx_dep_choices,opts={})
        ret = Hash.new
        return ret unless in_link_defs
        ndx_link_def_links = ndx_link_def_links(in_link_defs,base_cmp,opts)
        splice_link_def_and_dep_info(ndx_link_def_links,ndx_dep_choices)
      end

      def self.link_defs?(spliced_ndx_link_def_links)
        ret = nil
        return ret if spliced_ndx_link_def_links.empty?
        spliced_ndx_link_def_links.inject(Array.new) do |a,(link_def_type,link_def_links)|
          a + [link_def(link_def_type,link_def_links)]
        end
      end

    private
      def self.link_def(link_def_type,link_def_links)
        OutputHash.new(
          "type" => link_def_type,
          "required" =>  link_def_required?(link_def_links),
          "possible_links" => link_def_links.map{|link_def_link|link_def_link.possible_link()}
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
      def self.ndx_link_def_links(in_link_defs,base_cmp,opts={})
        ret = Hash.new
        convert_to_hash_form(in_link_defs) do |dep_cmp_name,link_def_links|
          link_def_links = [link_def_links] unless link_def_links.kind_of?(Array)
          link_def_links = convert_link_def_links(dep_cmp_name,link_def_links,base_cmp,opts)
          link_def_links.each do |ldl|
            ndx = ldl.dependency_name || dep_cmp_name
            (ret[ndx] ||= Array.new) << ldl
          end
        end
        ret
      end

      def self.convert_link_def_links(dep_cmp_name,link_def_links,base_cmp,opts={})
        link_def_links.inject(Array.new) do |a,link|
          unless link.kind_of?(Hash)
            err_msg = "The following link defs section on component '?1' is ill-formed: ?2"
            raise ParsingError.new(err_msg,component_print_form(base_cmp),{dep_cmp_name => link_def_links})
          end
          a + convert_link_def_link(link,dep_cmp_name,base_cmp,opts)
        end
      end

      def self.convert_link_def_link(link_def_link,dep_cmp_name,base_cmp,opts={})
        Choice::LinkDefLink.new(link_def_link,dep_cmp_name,base_cmp).convert(link_def_link,opts)
      end

      #------ end: related to ndx_link_def_links

      def self.splice_link_def_and_dep_info(ndx_link_def_links,ndx_dep_choices)
        ret = Hash.new
        ndx_link_def_links.each do |link_def_ndx,link_def_link_choices|
          pruned_ndx_dep_choices = ndx_dep_choices
          dep_name_match = false
          if dep_choices = ndx_dep_choices[link_def_ndx]
            pruned_ndx_dep_choices = {link_def_ndx => dep_choices}
            dep_name_match = true
          end
          link_def_link_choices.each do |ldl_choice|
            if dn = ldl_choice.dependency_name
              unless dep_name_match
                base_cmp_name = ldl_choice.base_cmp_print_form()
                dep_cmp_name = ldl_choice.dep_cmp_print_form()
                error_msg = "The link def segment on ?1: ?2\nreferences a dependency name (?3) that does not exist.\n"
                raise ParsingError.new(error_msg,base_cmp_name,{dep_cmp_name => ldl_choice.print_form},dn)
              end
            end
            unless ndx = matching_dep_index?(ldl_choice,pruned_ndx_dep_choices)
              ldl_choice.required = false
              ndx = ldl_choice.dep_cmp_ndx()
            end
            (ret[ndx] ||= Array.new) << ldl_choice
          end
        end
        ret
      end

      def self.matching_dep_index?(link_def_link_choice,ndx_dep_choices)
        ret = nil
        ndx_dep_choices.each do |dep_ndx,dep_choices|
          dep_choices.each do |dep_choice|
            if dep_choice.matches?(link_def_link_choice)
              return dep_ndx
            end
          end
        end
        ret
      end

      def self.raise_error_if_unmatched_remote_dep(ndx_dep_choices,spliced_ndx_link_def_links={})
        #see if there are any unmatched ndx_dep_choices that have a remote location
        ndx_dep_choices.each do |ndx,dep_choices|
          unless spliced_ndx_link_def_links[ndx]
            if remote_dep_choice = dep_choices.find{|ch|ch.remote_location?()}
              error_msg = "The following dependency on component '?base_cmp' has a remote location, but there is no matching link def: ?dep"
              raise ParsingError::Dependency.create(error_msg,remote_dep_choice)
            end
          end
        end
      end

    end
  end
end; end; end
