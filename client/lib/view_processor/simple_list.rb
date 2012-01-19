r8_require('hash_pretty_print')
require 'erubis'
module R8
  module Client
    class ViewProcSimpleList < ViewProcHashPrettyPrint
      def render(hash)
        pp_hash = super
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
