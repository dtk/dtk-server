module DTK; class ComponentDSL; class V3
  class ObjectModelForm; class Choice
    class LinkDef < self
      attr_reader :dependency_name
      def initialize(raw,dep_cmp_name,base_cmp)
        super(raw,dep_cmp_name,base_cmp)
        @dependency_name = nil
      end

      def self.link_defs(input_hash,base_cmp,ndx_dep_choices,opts={})
        ret = nil
        unless in_link_defs = input_hash["link_defs"]
          raise_error_if_unmatched_remote_dep(ndx_dep_choices)
          return ret
        end
        ndx_link_defs = ndx_link_defs_choice_form(in_link_defs,base_cmp,opts)
        spliced_ndx_link_defs = splice_link_def_and_dep_info(ndx_link_defs,ndx_dep_choices)
        raise_error_if_unmatched_remote_dep(ndx_dep_choices,spliced_ndx_link_defs)

        ret = Array.new
        spliced_ndx_link_defs.each do |link_def_type,choices|
pp [:choice,link_def_type,choices,choices[0].class]
          choices.each do |choice|
            link_def = OutputHash.new(
              "type" => link_def_type,
              "required" =>  true, #TODO: will enhance so that check if also dependency
              "possible_links" => choices.map{|choice|choice.possible_link()}
            )
            ret << link_def
          end
        end
        ret
      end

      class_calls_private_instance :convert_link_def_link
      #def convert_link_def_link__public(link_def_link,opts={})
      #  convert_link_def_link(link_def_link,opts)
      #end

    private
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
        new(link_def_link,dep_cmp_name,base_cmp).convert_link_def_link__public(link_def_link,opts)
      end

      def convert_link_def_link(link_def_link,opts={})
        in_attr_mappings = link_def_link["attribute_mappings"]
        if (in_attr_mappings||[]).empty?
          err_msg = "The following link defs section on component '?1' is missing the attribute mappings section: ?2"
          raise ParsingError.new(err_msg,base_cmp_print_form(),{dep_cmp_print_form() => link_def_link})
        end

        unless type = opts[:link_type] || link_def_link_type(link_def_link)
          ret = [dup().convert_link_def_link__public(link_def_link,:link_type => :external).first,
                 dup().convert_link_def_link__public(link_def_link,:link_type => :internal).first]
          return ret
        end
        ret_info = {"type" => type.to_s}
        
        #TODO: pass in order from what is on dependency
        if order = opts[:order]||order(link_def_link)
          ret_info["order"] = order 
        end
        
        ret_info["attribute_mappings"] = in_attr_mappings.map{|in_am|convert_attribute_mapping(in_am,base_cmp(),dep_cmp(),opts)}
        
        @possible_link.merge!(dep_cmp() => ret_info)
        @dependency_name = link_def_link["dependency_name"]
        [self]
      end

      def link_def_link_type(link_info)
        if loc = link_info["location"]
          case loc
          when "local" then "internal"
          when "remote" then "external"
          else raise ParsingError.new("Ill-formed dependency location type (?1)",loc)
          end
        end
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
  end; end
end; end; end
