module DTK
  module ServiceDSLCommonMixin
    Seperators = {
      :module_component => "::", #TODO: if this changes need to change ModCompGsub
      :component_version => ":",
      :component_port => "/",
      :assembly_node => "/",
      :node_component => "/",
      :component_link_def_ref => "/"
    }
    ModCompInternalSep = "__" #TODO: if this changes need to chage ModCompGsub[:sub]
    ModCompGsub = {
      :pattern => /(^[^:]+)::/, 
      :sub => '\1__'
    }
    CmpVersionRegexp = Regexp.new("(^.+)#{Seperators[:component_version]}([0-9]+.+$)")

    module InternalForm
      def self.component_ref(cmp_type_ext_form)
        cmp_type_ext_form.gsub(ModCompGsub[:pattern],ModCompGsub[:sub])
      end

      #returns [ref,component_type,version] where version can be nil
      def self.component_ref_type_and_version(cmp_type_ext_form)
        ref = component_ref(cmp_type_ext_form)
        if ref =~ CmpVersionRegexp
          type = $1; version = $2
        else
          type = ref; version = nil
        end
        [ref,type,version]
      end
    end

    class AssemblyImportPortRef < SimpleHashObject
      def self.parse(port_ref,assembly_id=nil)
        #TODO: may need to update this to handle port refs with titles
        if port_ref =~ PortRefRegex
          node = $1; cmp_name = $2; link_def_ref = $3
          hash = {:node => node,:component_type => component_type_internal_form(cmp_name),:link_def_ref => link_def_ref}
          if assembly_id
            hash.merge!(:assembly_id => assembly_id)
          end
          new(hash)
        else
          raise Error.new("ill-formed port ref (#{port_ref})")
        end     
      end
      def self.parse_component_link(input_node,input_cmp_name,component_link_hash)
        unless component_link_hash.size == 1
          raise Error.new("ill-formed component link (#{component_link_hash.inject})")
        end
        link_def_ref = component_link_hash.keys.first
        if component_link_hash.values.first =~ ServiceLinkTarget
          output_node = $1; output_cmp_name = $2
          input = parsed_endpoint(input_node,input_cmp_name,link_def_ref)
          output = parsed_endpoint(output_node,output_cmp_name,link_def_ref)
          {:input => input, :output => output}
        else
          raise Error.new("ill-formed component link (#{component_link_hash.inject}")
        end     
      end
      class << self
       private
        def parsed_endpoint(node,cmp_name,link_def_ref)
          component_type,title = ComponentTitle.parse_component_display_name(cmp_name)
          ret_hash = {:node => node,:component_type => component_type_internal_form(component_type), :link_def_ref => link_def_ref}
          ret_hash.merge!(:title => title) if title
          new(ret_hash)
        end

        def component_type_internal_form(cmp_type_ext_form)
          #TODO: this does not take into account that there could be a version on cmp_type_ext_form
          InternalForm.component_ref(cmp_type_ext_form)
        end
      end
      PortRefRegex = Regexp.new("(^.+)#{Seperators[:node_component]}(.+)#{Seperators[:component_link_def_ref]}(.+$)")
      ServiceLinkTarget= Regexp.new("(^.+)#{Seperators[:node_component]}(.+$)")

      #ports are augmented with field :parsed_port_name
      def matching_id(aug_ports,opts={})
        if opts[:is_output]
          if self[:title]
            err_class = ErrorUsage::DSLParsing::NotSupported::LinkFromComponentWithTitle
            return raise_or_ret_error(err_class,[self[:node],self[:component_type],self[:title]],opts)
          end
        end
        match = aug_ports.find do |port|
          p = port[:parsed_port_name]
          node = port[:node][:display_name]
          if self[:component_type] == p[:component_type] and self[:link_def_ref] == p[:link_def_ref] and node == self[:node] 
            if self[:assembly_id].nil? or (self[:assembly_id] == port[:assembly_id])
              self[:title] == p[:title] #they both can be nil -> want a match
            end
          end
        end
        if match
          match[:id]
        elsif opts[:do_not_throw_error]
          opts_file_path = Aux::hash_subset(opts,[:file_path])
          return ErrorUsage::DSLParsing::BadComponentLink.new(self[:node],self[:component_type],self[:link_def_ref],opts_file_path)
        else
          raise Error.new("Cannot find match to (#{self.inspect})")
        end
      end

      def raise_or_ret_error(err_class,args,opts={})
        opts_file_path = Aux::hash_subset(opts,[:file_path])
        err = err_class.new(*args,opts_file_path)
        opts[:do_not_throw_error] ? err : raise(err)
      end
      private :raise_or_ret_error

      class AddOn < self
        #returns assembly ref, port_ref
        def self.parse(add_on_port_ref,assembly_list)
          assembly_name,port_ref = (add_on_port_ref =~ AOPortRefRegex; [$1,$2])
          unless assembly_match = assembly_list.find{|a|a[:display_name] == assembly_name}
            assembly_names = assembly_list.map{|a|a[:display_name]}
            Log.error("Assembly name in add-on port link (#{assembly_name}) is illegal; must be one of (#{assembly_names.join(',')})")
#            raise ErrorUsage.new("Assembly name in add-on port link (#{assembly_name}) is illegal; must be one of (#{assembly_names.join(',')})")
          end
          [assembly_name,super(port_ref,assembly_match[:id])]
        end
        AOSep = Seperators[:assembly_node]
        AOPortRefRegex = Regexp.new("(^[^#{AOSep}]+)#{AOSep}(.+$)")
      end
    end
  end
end
