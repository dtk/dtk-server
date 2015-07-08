module DTK; class ServiceModule
  class ParsingError
    class RemovedServiceInstanceCmpRef < self
      attr_reader :cmp_ref_info_list
      def initialize(cmp_ref_info_list,opts={})
        super(err_msg(cmp_ref_info_list),opts)
        # each element can be a component ref object or a hash
        @cmp_ref_info_list = cmp_ref_info_list
      end

      private

      def err_msg(cmp_ref_info_list)
        what = (cmp_ref_info_list.size==1 ? "component" : "components")
        refs = cmp_ref_info_list.map{|cmp_ref_info|print_form(cmp_ref_info)}.compact.join(",")
        is = (cmp_ref_info_list.size==1 ? "is" : "are")
        does = (cmp_ref_info_list.size==1 ? "does" : "do")
        "You are not allowed to delete #{what} (#{refs}) that #{is} referenced in component module used in this service instance"
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
