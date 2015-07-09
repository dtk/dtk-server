module XYZ
  class DB
    module RestContent
      def self.ret_instance_summary(id_info_row, href_prefix, opts = {})
        qualified_ref = id_info_row.ret_qualified_ref()
  link_self = opts[:no_hrefs] ? {} : ret_link(:self, id_info_row[:uri], href_prefix)
        #key, value
        [qualified_ref.to_sym,
          { id: id_info_row[:id], display_name: id_info_row[:display_name] ? id_info_row[:display_name].to_s : qualified_ref }.merge(link_self)]
      end

      def self.ret_link(rel, href_path, href_prefix)
        { link: { rel: rel, href: href_prefix + href_path } }
      end
    end
  end
end
