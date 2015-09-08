module DTK; class ServiceModule; class AssemblyExport
  module FoldIntoExisting
    class AssemblySectionProc
      attr_reader :raw_array

      def initialize(raw_array = [])
        @raw_array = raw_array
      end

      def parse_and_order_components_hash(assembly_hash)
        cmps_first, parsed_content = parse_existing_and_remove_unused()
        nodes_content  = split_by_nodes(parsed_content)
        order_nodes_hash(assembly_hash, nodes_content, cmps_first)
      end

      private

      def parse_existing_and_remove_unused
        ignore      = true
        new_array   = []
        node_name   = nil
        node_indent = nil
        components_first = nil
        component_links = false
        component_links_indent = nil
        component_name = nil

        @raw_array.each do |el|
          is_node = nil
          name    = el.strip

          if name.eql?('assembly:')
            ignore = false
          elsif name.eql?('workflow:') or name.eql?('workflows:')
            ignore = true
          end

          unless ignore
            if name.empty? || name.start_with?('#')
              new_array << { name: name, content: el, node: node_name }
            elsif name.start_with?('- ')
              new_array << { name: name, content: el, node: node_name }
            else
              if last_name = new_array.last && new_array.last[:name]
                components_first = true if name.eql?('components:') && node_name.nil?
                if last_name.eql?('nodes:')
                  is_node     = true
                  node_name   = name
                  node_indent = el[/\A */].size
                elsif node_indent
                  if el[/\A */].size == node_indent
                    is_node   = true
                    node_name = name
                  end
                end

                if last_name.strip.start_with?('- ') && !is_node && !name.eql?('nodes:')
                  if name.eql?('component_links:')
                    component_name = last_name
                    new_array << { node_name: node_name, component_name: component_name, name: name }
                    component_links = true
                  else
                    content = new_array.last[:content]
                    new_array.last[:content] = content + el
                  end
                elsif last_name.eql?('component_links:')
                  component_links = true
                  component_links_indent = el[/\A */].size
                  new_array << { node_name: node_name, component_name: component_name, name: name }
                elsif component_links && el[/\A */].size == component_links_indent
                  new_array << { node_name: node_name, component_name: component_name, name: name }
                else
                  component_links = false
                  if match = name.match(/(\w+:)\s*(\w+)/)
                    name = match[1] if match[1] && match[2]
                  end
                  new_array << { name: name, content: el, node: node_name }
                end
              else
                new_array << { name: name, content: el }
              end
            end
          end
        end

        [components_first, new_array]
      end

      def split_by_nodes(parsed_content)
        nodes_hash = {}
        ignore     = true
        component_links = {}

        parsed_content.each do |el|
          name = el[:name]
          ignore = false if name.eql?('components:') && el[:node]
          unless ignore
            if el[:component_name]
              component_name = el[:component_name].gsub(/^- /, '').chomp(':')
              component_links[el[:node_name]] = {} unless component_links[el[:node_name]]
              component_links[el[:node_name]][component_name] = [] unless component_links[el[:node_name]][component_name]
              component_links[el[:node_name]][component_name] << name.strip.gsub(/^- /, '') unless name.eql?('component_links:')
            else
              nodes_hash[el[:node]] = [] unless nodes_hash[el[:node]]
              nodes_hash[el[:node]] << name
            end
          end
        end

        { nodes: nodes_hash, component_links: component_links }
      end

      def order_nodes_hash(assembly_hash, nodes_content, cmps_first)
        assembly_hash_nodes = assembly_hash[:assembly][:nodes]
        existing_cmp_links  = nodes_content[:component_links]
        new_assembly_nodes  = {}

        nodes_content[:nodes].each do |k, v|
          next if k.nil?

          node_name = k.chomp(':')
          assembly_node = assembly_hash_nodes.delete(node_name)
          node_cmp_links = existing_cmp_links[k]

          if assembly_node
            assembly_node_components     = assembly_node[:components]
            new_assembly_node_components = []

            unless assembly_node_components.empty?
              v.each do |ex_cmp_name|
                next if ex_cmp_name.eql?('components:') && v.index(ex_cmp_name) == 0

                new_assembly_node_components << ex_cmp_name if ex_cmp_name.eql?('') || ex_cmp_name.start_with?('#')
                ex_cmp_name_formatted = ex_cmp_name.chomp(':').gsub(/\A- /, '')

                assembly_node_components.each do |an_cmp|
                  if an_cmp.is_a?(String)
                    if ex_cmp_name_formatted.eql?(an_cmp)
                      existin_node_component = assembly_node_components.delete(an_cmp)
                      new_assembly_node_components << existin_node_component
                    end
                  elsif an_cmp.is_a?(Hash)
                    an_cmp_name = an_cmp.keys.first
                    if ex_cmp_name_formatted.eql?(an_cmp_name)
                      existin_node_component = assembly_node_components.delete(an_cmp)
                      order_component_links!(existin_node_component, node_cmp_links, an_cmp_name) if existin_node_component && node_cmp_links
                      new_assembly_node_components << existin_node_component
                    end
                  else
                    raise Error.new, 'Unknown component format'
                  end
                end
              end
            end

            new_assembly_node_components.concat(assembly_node_components) unless assembly_node_components.empty?
            assembly_node[:components] = new_assembly_node_components
            new_assembly_nodes.merge!(node_name => assembly_node)
          end
        end

        assembly_hash[:assembly][:nodes] = new_assembly_nodes.merge(assembly_hash_nodes)
        assembly_hash[:assembly][:nodes] = assembly_hash[:assembly].delete(:nodes) if cmps_first
        assembly_hash
      end

      def order_component_links!(existin_node_component, node_cmp_links, an_cmp)
        return unless existin_node_component[an_cmp] && existin_node_component[an_cmp][:component_links]
        existing_node_cmp_links = existin_node_component[an_cmp][:component_links]
        new_cmp_links = {}

        if cmp_links = existing_node_cmp_links && node_cmp_links[an_cmp]
          cmp_links.each do |cmp_link|
            if match = find_matching_cmp_links(cmp_link, existing_node_cmp_links)
              new_cmp_links.merge!(match)
            end
          end
        end

        new_cmp_links.merge!(existing_node_cmp_links)
        existin_node_component[an_cmp][:component_links] = new_cmp_links
      end

      def find_matching_cmp_links(cmp_link, existing_node_cmp_links)
        matching_cmp = nil

        existing_node_cmp_links.each do |k,v|
          formatted_value = v.gsub('assembly_wide/', '')
          matching_cmp = { k => existing_node_cmp_links.delete(k) } if cmp_link.eql?("#{k}: #{formatted_value}")
        end

        matching_cmp
      end
    end
  end
end; end; end

