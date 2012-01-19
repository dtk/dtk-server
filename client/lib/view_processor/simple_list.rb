require 'erubis'
module R8
  module Client
    class ViewProcSimpleList < ViewProcessor
      def render(hash,ident=0)
        pp_adapter = ViewProcessor.get_adapter("hash_pretty_print",@command_class)
        ordered_hash = pp_adapter.render(hash)
        #TODO: need to break apart if has nested hashes
        scalar_value_render(ordered_hash,ident)
      end
     private
      def scalar_value_render(ordered_hash,ident)
        template_bindings = {
          :ordered_hash => ordered_hash,
          :ident => ident_str(ident),
          :identp2 => ident_str(ident+2)
        }
        SimpleListTemplate.result(template_bindings)

      end
      def ident_str(n)
        Array.new(n, " ").join
      end
SimpleListTemplate = Erubis::Eruby.new <<eos
<% keys = ordered_hash.keys %>
<% first = keys.shift  %>
<%= ident %><%= ordered_hash[first] %>
<% keys.each do |k| %>
<%= identp2 %><%= k %>:  <%= ordered_hash[k] %>
<% end %>
eos

    end
  end
end
