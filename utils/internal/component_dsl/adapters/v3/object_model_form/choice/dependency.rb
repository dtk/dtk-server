module DTK; class ComponentDSL; class V3
  class ObjectModelForm; class Choice
    class Dependency < self
      def self.convert_choices(conn_ref,conn_info_x,base_cmp,opts={})
        conn_info =
          if conn_info_x.kind_of?(Hash)
            conn_info_x
          elsif conn_info_x.kind_of?(Array) and conn_info_x.size == 1 and conn_info_x.first.kind_of?(Hash)
            conn_info_x.first
          else
            base_cmp_name = component_print_form(base_cmp)
            err_msg = 'The following dependency on component (?1) is ill-formed: ?2'
            raise ParsingError.new(err_msg,base_cmp_name,{conn_ref => conn_info_x})
          end
        if choices = conn_info["choices"]
          opts_choices = opts.merge(:conn_ref => conn_ref)
          choices.map{|choice|convert_choice(choice,base_cmp,conn_info,opts_choices)}
        else
          dep_cmp_external_form = conn_info["component"]||conn_ref
          parent_info = Hash.new
          [convert_choice(conn_info.merge("component" => dep_cmp_external_form),base_cmp,parent_info,opts)]
        end
      end

     private
      def self.convert_choice(dep_cmp_info,base_cmp,parent_info={},opts={})
        new(dep_cmp_info,dep_cmp_info["component"],base_cmp).convert(dep_cmp_info,base_cmp,parent_info,opts)
      end
    end
  end; end
end; end; end
