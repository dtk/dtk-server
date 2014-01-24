module DTK; class ComponentDSL; class V3
  class ObjectModelForm
    class LinkDef < OMFBase
      def self.link_defs(input_hash,base_cmp,ndx_dep_choices,opts={})
        ret = nil
        unless in_link_defs = input_hash["link_defs"]
          raise_error_if_unmatched_remote_dep(ndx_dep_choices)
          return ret
        end
        ndx_link_defs = ndx_link_defs_choice_form(in_link_defs,base_cmp,opts)
        spliced_ndx_link_defs = splice_link_def_and_dep_info(ndx_link_defs,ndx_dep_choices)
        raise_error_if_unmatched_remote_dep(ndx_dep_choices,spliced_ndx_link_defs)

pp [:link_defs,spliced_ndx_link_defs]
        spliced_ndx_link_defs.inject(Array.new) do |a,(link_def_type,link_def_links)|
          a + [link_def(link_def_type,link_def_links)]
        end
      end

    private
      def self.link_def(link_def_type,link_def_links)
        OutputHash.new(
          "type" => link_def_type,
          "required" =>  true, #TODO: will enhance so that check if also dependency
          "possible_links" => link_def_links.map{|link_def_link|link_def_link.possible_link()}
        )
      end

      #------ begin: related to ndx_link_defs_choice_form
      def self.ndx_link_defs_choice_form(in_link_defs,base_cmp,opts={})
        ret = Hash.new
        convert_to_hash_form(in_link_defs) do |dep_cmp_name,link_def_links|
          link_def_links = [link_def_links] unless link_def_links.kind_of?(Array)
          choices = convert_choices(dep_cmp_name,link_def_links,base_cmp,opts)
          choices.each do |choice|
            ndx = choice.dependency_name || dep_cmp_name
            (ret[ndx] ||= Array.new) << choice
          end
        end
        ret
      end

      def self.convert_choices(dep_cmp_name,link_def_links,base_cmp,opts={})
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

      #------ end: related to ndx_link_defs_choice_form

      def self.splice_link_def_and_dep_info(ndx_link_defs,ndx_dep_choices)
        ret = Hash.new
        ndx_link_defs.each do |link_def_ndx,link_def_choices|
          pruned_ndx_dep_choices = ndx_dep_choices
          dep_name_match = false
          if dep_choices = ndx_dep_choices[link_def_ndx]
            pruned_ndx_dep_choices = {link_def_ndx => dep_choices}
            dep_name_match = true
          end
          link_def_choices.each do |link_def_choice|
            if dn = link_def_choice.dependency_name
              unless dep_name_match
                base_cmp_name = link_def_choice.base_cmp_print_form()
                dep_cmp_name = link_def_choice.dep_cmp_print_form()
                error_msg = "The link def segment on ?1: ?2\nreferences a dependency name (?3) that does not exist.\n"
                raise ParsingError.new(error_msg,base_cmp_name,{dep_cmp_name => link_def_choice.print_form},dn)
              end
            end
            unless ndx = find_index(link_def_choice,pruned_ndx_dep_choices)
              base_cmp_name = link_def_choice.base_cmp_print_form()
              dep_cmp_name = link_def_choice.dep_cmp_print_form()
              error_msg = "Cannot find dependency match for link_def for component '?1' to '?2'; the link fragment is: ?3"
              raise ParsingError.new(error_msg,base_cmp_name,dep_cmp_name,{dep_cmp_name => link_def_choice.print_form()})
            end
            (ret[ndx] ||= Array.new) << link_def_choice
          end
        end
        ret
      end

      def self.find_index(link_def_choice,ndx_dep_choices)
        ret = nil
        ndx_dep_choices.each do |dep_ndx,dep_choices|
          dep_choices.each do |dep_choice|
            if dep_choice.matches?(link_def_choice)
              return dep_ndx
            end
          end
        end
        ret
      end

      def self.raise_error_if_unmatched_remote_dep(ndx_dep_choices,spliced_ndx_link_defs={})
        #see if there are any unmatched ndx_dep_choices that have a remote location
        ndx_dep_choices.each do |ndx,dep_choices|
          unless spliced_ndx_link_defs[ndx]
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
