#TODO: test for assembly list/display; want to make assembly specfic stuff datadriven
r8_require 'simple_list'
module R8
  module Client
    class ViewProcSimpleList2 < ViewProcSimpleList
     private
      def simple_value_render(ordered_hash,ident_info)
        #process elements that are not scalars
        updated_els = Hash.new
        ordered_hash.each do |k,v|
          unless is_scalar_type?(v)
            updated_els[k] = convert_to_string_form(v)
          end
        end
        proc_ordered_hash = ordered_hash.merge(updated_els)

        prefix = 
          if ident_info[:include_first_key]
            ident_str(IdentAdd) + ordered_hash.keys.first + KeyValSeperator
          else
            (ident_info[:prefix] ? (ident_info[:prefix] + KeyValSeperator) : "")
          end
        ident = ident_info[:ident]||0
        first_prefix = ident_str(ident)
        rest_prefix = ident_str(ident+IdentAdd)
        type = ident_info[:prefix] && ident_info[:prefix].gsub(/s$/,"").to_sym #TODO: hack
    pp [type, ordered_hash.object_type,"#{proc_ordered_hash.values.first}"]
        unless (type == :attribute) 
          first_value = "#{proc_ordered_hash.values.first}"
          template_bindings = {
            :ordered_hash => proc_ordered_hash,
            :first_prefix => first_prefix,
            :rest_prefix => rest_prefix,
            :sep => KeyValSeperator,
            :first_value => first_value
          }
          SimpleListTemplate2.result(template_bindings)
        else
          p = proc_ordered_hash
          augment = (p["override"] ? " (override)" : "")
          "#{first_prefix}#{p["attribute_name"]} = #{p["value"]}#{augment}\n"
        end
      end
SimpleListTemplate2 = Erubis::Eruby.new <<eos
<% keys = ordered_hash.keys %>
<% first = keys.shift  %>
<%= first_prefix %><%= first_value %>
<% keys.each do |k| %>
<%= rest_prefix %><%= k %><%= sep  %><%= ordered_hash[k] %>
<% end %>
eos
    end
  end
end
