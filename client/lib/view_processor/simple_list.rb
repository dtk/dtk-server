require 'erubis'
module R8
  module Client
    class ViewProcSimpleList < ViewProcessor
      def render(hash)
        pp_adapter = ViewProcessor.get_adapter("hash_pretty_print",@command_class)
        pp_hash = pp_adapter.render(hash)
        template_bindings = {
          :pretty_print_hash => pp_hash
        }
        SimpleListTemplate.result(template_bindings)

      end
SimpleListTemplate = Erubis::Eruby.new <<eos
<% keys = pretty_print_hash.keys %>
<% first = keys.shift  %>
<%= pretty_print_hash[first] %>
<% keys.each do |k| %>
  <%= k %>:  <%= pretty_print_hash[k] %>
<% end %>
eos

    end
  end
end
