module DTK
  class AttributeLink
    class AdHoc < Hash
      #Logic is if update meta then meta updated as well as ad_hoc updates for existing component instances
      #TODO: this gives us what is like mixed mode where insatnces created already will have ad hoc attribute links, while new ones wil have service links
      def self.create_adhoc_links(assembly,target_attr_term,source_attr_term,opts={})
        parsed_adhoc_links = attribute_link_hashes(assembly.id_handle(),target_attr_term,source_attr_term)
#TODO: debug
opts[:update_meta] = true
        if opts[:update_meta]
Transaction do
          result = AssemblyModule::Component.update_from_adhoc_links(assembly,parsed_adhoc_links,opts)
          if link_def_info = result[:link_def_created]
            link_def_hash = link_def_info[:hash_form]
            dep_cmp = result[:dep_component]
            antec_cmp = result[:antec_component]
            create_link_defs_and_service_links(assembly,parsed_adhoc_links,dep_cmp,antec_cmp,link_def_hash)
          else
            #TODO: this should be changed to adding service links rather than adhoc links
            #alos it looks like it can get which end is dependent wrong
            create_ad_hoc_attribute_links?(assembly,parsed_adhoc_links,:all_dep_component_instances=>true)
          end
end
        else
          create_ad_hoc_attribute_links?(assembly,parsed_adhoc_links)
        end
      end

      # type should be :source or :target
      def attribute_pattern(type)
        @attr_pattern[type]
      end

      def all_dep_component_instance_hashes()
        ret = [self]
        #get peer component instances
        cmp_instance = attribute_pattern(:target).component_instance
        peer_cmps = @assembly_idh.create_object().get_peer_component_instances(cmp_instance)
        return ret if peer_cmps.empty?
        #find the matching attributes on the peer components
        sp_hash = {
          :cols => [:id,:group_id,:display_name],
          :filter => [:and,[:oneof,:component_component_id,peer_cmps.map{|cmp|cmp.id()}],
                      [:eq,:display_name,attribute_pattern(:target).attribute_name]]
        }
        assembly_id = @assembly_idh.get_id()
        output_attr_id = attribute_pattern(:source).attribute_id()
        peer_attrs = Model.get_objs(@assembly_idh.createMH(:attribute),sp_hash).map do |input_attr|
          {
            :input_id => input_attr.id(),
            :output_id => output_attr_id,
            :assembly_id => assembly_id
          }
        end
        
        ret + peer_attrs
      end

     private
      def initialize(hash,assembly_idh,target_attr_pattern,source_attr_pattern)
        super()
        replace(hash)
        @assembly_idh = assembly_idh
        @attr_pattern = {
          :target => target_attr_pattern,
          :source => source_attr_pattern.attribute_pattern
        }
      end

      def self.create_link_defs_and_service_links(assembly,parsed_adhoc_links,dep_cmp,antec_cmp,link_def_hash)
        #This method iterates over all the components in assembly that includes dep_cmp and its peers and for each
        #adds the link_def to it and then service link between this and antec_cmp
        service_type = link_def_hash.keys
        antec_cmp_idh = antec_cmp.id_handle()
        (dep_cmp + assembly.get_peer_component_instances(dep_cmp)).each do |cmp|
           #TODO: can be more efficient to combine these two operations and see if can bulk them
           cmp_idh = cmp.id_handle()
           Model.input_hash_content_into_model(cmp_idh,:link_def => link_def_hash)
           assembly.add_service_link?(service_type,cmp_idh,antec_cmp_idh)
         end
       end

      def self.create_ad_hoc_attribute_links?(assembly,parsed_adhoc_links,opts={})
        if opts[:all_dep_component_instances]
          attr_link_rows = parsed_adhoc_links.inject(Array.new) do |a,adhoc_link|
            a + adhoc_link.all_dep_component_instance_hashes()
          end
          create_ad_hoc_attribute_links_aux?(assembly,attr_link_rows)
        else
          create_ad_hoc_attribute_links_aux?(assembly,parsed_adhoc_links)
        end
      end

      def self.create_ad_hoc_attribute_links_aux?(assembly,attr_link_rows)
        ret = Array.new
        existing_links = get_matching_ad_hoc_attribute_links(assembly,attr_link_rows)
        new_links = attr_link_rows.reject do |link|
          existing_links.find do |existing_link|
            existing_link[:output_id] == link[:output_id] and
              existing_link[:input_id] == link[:input_id]
          end
        end
        return ret if new_links.empty?
        opts_create = {
          :donot_update_port_info => true,
          :donot_create_pending_changes => true
        }
        AttributeLink.create_attribute_links(assembly.id_handle(),new_links,opts_create)
      end

      def self.get_matching_ad_hoc_attribute_links(assembly,attr_link_rows)
        ret = Array.new
        return ret if attr_link_rows.empty?
        assembly_id = assembly.id()
        disjunct_array = attr_link_rows.map do |r|
          [:and,[:eq,:assembly_id,assembly_id],
           [:eq,:output_id,r[:output_id]],
           [:eq,:input_id,r[:input_id]]]
        end
        sp_hash = {
          :cols => [:id,:group_id,:assembly_id,:input_id,:output_id],
          :filter => [:or] + disjunct_array
        }
        Model.get_objs(assembly.model_handle(:attribute_link),sp_hash)
      end

      def self.attribute_link_hashes(assembly_idh,target_attr_term,source_attr_term)
        target_attr_pattern = Attribute::Pattern::Assembly.create_attr_pattern(assembly_idh,target_attr_term)
        if target_attr_pattern.attribute_idhs.empty?
          raise ErrorUsage.new("No matching attribute to target term (#{target_attr_term})")
        end
        source_attr_pattern = Attribute::Pattern::Assembly::Source.create_attr_pattern(assembly_idh,source_attr_term)
        
        #TODO: need to do more chaecking and processing to include:
        #  if has a relation set already and scalar conditionally reject or replace
        # if has relation set already and array, ...
        attr_info = {
          :assembly_id =>  assembly_idh.get_id(),
          :output_id => source_attr_pattern.attribute_idh.get_id()
        }
        if fn = source_attr_pattern.fn()
          attr_info.merge!(:function => fn) 
        end

        target_attr_pattern.attribute_idhs.map do |target_attr_idh|
          hash = attr_info.merge(:input_id => target_attr_idh.get_id())
          new(hash,assembly_idh,target_attr_pattern,source_attr_pattern)
        end
      end
    end
  end
end

