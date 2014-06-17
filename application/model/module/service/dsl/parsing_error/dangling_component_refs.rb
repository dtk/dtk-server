module DTK; class ServiceModule
  class ParsingError
    class ParsingError::DanglingComponentRefs < self
      def initialize(cmp_ref_info_list,opts={})
        super(err_msg(cmp_ref_info_list),opts)
        # each element can be a component ref object or a hash
        @cmp_ref_info_list = cmp_ref_info_list 
      end

      #
      # Returns list of missing modules with version
      #
      def missing_module_list()
        # forming hash and then getting its vals to remove dups in same <module,version,namepsace>
        module_hash = @cmp_ref_info_list.inject(Hash.new) do |h,r|
          module_name = r[:component_type].split('__').first
          remote_namespace = r[:remote_namespace]
          ndx = "#{module_name}---#{r[:version]}---#{remote_namespace}"
          info = {
            :name => module_name, 
            :version => r[:version]
          }
          info.merge!(:remote_namespace => remote_namespace) if remote_namespace
          h.merge!(ndx => info)
        end
        
        module_hash.values
      end
      
      attr_reader :cmp_ref_info_list
      
      class Aggregate 
        def initialize(opts={})
          @cmp_ref_info_list = Array.new
          @error_cleanup = opts[:error_cleanup]
        end
        
        def aggregate_errors!(ret_when_err=nil,&block)
          begin
            yield
          rescue ParsingError::DanglingComponentRefs => e
            @cmp_ref_info_list = ret_unique_union(@cmp_ref_info_list,e.cmp_ref_info_list)
            ret_when_err
          rescue Exception => e
            @error_cleanup.call() if @error_cleanup
            raise e
          end
        end
        
        def raise_error?(opts={})
          unless @cmp_ref_info_list.empty?()
            @error_cleanup.call() if @error_cleanup
            opts_err = Opts.new(:log_error => false)
            return ParsingError::DanglingComponentRefs.new(@cmp_ref_info_list,opts_err) if opts[:do_not_raise]
            raise ParsingError::DanglingComponentRefs.new(@cmp_ref_info_list,opts_err)
          end
        end
        
        private
        def ret_unique_union(cmp_refs1,cmp_refs2)
          ndx_ret = cmp_refs1.inject(Hash.new){|h,r|h.merge(ret_unique_union__ndx(r) => r)}
          cmp_refs2.inject(ndx_ret){|h,r|h.merge(ret_unique_union__ndx(r) => r)}.values
        end
        
        def ret_unique_union__ndx(cmp_ref_info)
          ret = cmp_ref_info[:component_type]
          if version = cmp_ref_info[:version]
            ret = "#{ret}(#{version})"
          end
          ret
        end
        
      end

     private
      def err_msg(cmp_ref_info_list)
        what = (cmp_ref_info_list.size==1 ? "component template" : "component templates")
        refs = cmp_ref_info_list.map{|cmp_ref_info|print_form(cmp_ref_info)}.compact.join(",")
        is = (cmp_ref_info_list.size==1 ? "is" : "are")
        does = (cmp_ref_info_list.size==1 ? "does" : "do")
        "The following #{what} (#{refs}) that #{is} referenced by assemblies in the service module #{does} not exist; this can be rectified by invoking the 'push' command after manually loading appropriate component module(s) or by removing references in the service DSL file(s)"
      end
      
      def print_form(cmp_ref_info)
        ret = ComponentRef.print_form(cmp_ref_info)
        if version = cmp_ref_info[:version]
          ret = "#{ret}(#{version})"
        end
        ret
      end
    end
  end
end; end
