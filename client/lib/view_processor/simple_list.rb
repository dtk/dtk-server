require 'erubis'
module R8
  module Client
    class ViewProcSimpleList < ViewProcessor
      def render(hash,ident_info={})
        pp_adapter = ViewProcessor.get_adapter("hash_pretty_print",@command_class)
        ordered_hash = pp_adapter.render(hash)
        #find next value that is type pretty print hash or array
        first,nested,rest = find_first_non_scalar(ordered_hash)
        ret = String.new
        unless first.empty?
          ret = scalar_value_render(first,ident_info)
        end
        unless nested.empty?
          ident_info_nested = {
            :ident => (ident_info[:ident]||0) +IdentAdd,
            :prefix => nested.keys.first
          }
          vals = nested.values.first
          vals = [vals] unless vals.kind_of?(Array)
          vals.each{|val|ret << render(val,ident_info_nested)}
        end
        unless rest.empty?
          ret << render(rest,ident_info)
        end
        ret
      end
     private

      IdentAdd = 2
      def find_first_non_scalar(ordered_hash)
        found = nil
        keys = ordered_hash.keys
        keys.each_with_index do |k,i|
          if ordered_hash[k].kind_of?(Hash) or ordered_hash[k].kind_of?(Array)
            found = i
            break
          end
        end
        if found.nil?
          empty_ordered_hash = ordered_hash.class.new
          [ordered_hash,empty_ordered_hash,empty_ordered_hash]
        else
          [keys[0,found],keys[found,1],keys[found+1,keys.size-1]].map{|key_array|ordered_hash.slice(*key_array)}
        end
      end

      def scalar_value_render(ordered_hash,ident_info)
        prefix = (ident_info[:prefix] ? (ident_info[:prefix] + KeyValSeperator) : "")
        ident = ident_info[:ident]||0
        first_prefix = ident_str(ident) + prefix
        rest_prefix = ident_str(ident+IdentAdd)
        template_bindings = {
          :ordered_hash => ordered_hash,
          :first_prefix => first_prefix,
          :rest_prefix => rest_prefix,
          :sep => KeyValSeperator
        }
        SimpleListTemplate.result(template_bindings)

      end
      def ident_str(n)
        Array.new(n, " ").join
      end
      KeyValSeperator = ": "
SimpleListTemplate = Erubis::Eruby.new <<eos
<% keys = ordered_hash.keys %>
<% first = keys.shift  %>
<%= first_prefix %><%= ordered_hash[first] %>
<% keys.each do |k| %>
<%= rest_prefix %><%= k %><%= sep  %><%= ordered_hash[k] %>
<% end %>
eos

    end
  end
end
