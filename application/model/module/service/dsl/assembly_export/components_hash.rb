module DTK; class ServiceModule
  class AssemblyExport
    class ComponentsHash
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

        @raw_array.each do |el|
          is_node = nil
          name    = el.strip

          if name.eql?('assembly:')
            ignore = false
          elsif name.eql?('workflow:')
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

                if last_name.strip.start_with?('- ') && !is_node
                  content = new_array.last[:content]
                  new_array.last[:content] = content + el
                else
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

        parsed_content.each do |el|
          ignore = false if el[:name].eql?('components:')
          unless ignore
            nodes_hash[el[:node]] = [] unless nodes_hash[el[:node]]
            nodes_hash[el[:node]] << el[:name]
          end
        end

        { nodes: nodes_hash }
      end

      def order_nodes_hash(assembly_hash, nodes_content, cmps_first)
        assembly_hash_nodes = assembly_hash[:assembly][:nodes]
        new_assembly_nodes  = {}

        nodes_content[:nodes].each do |k, v|
          next if k.nil?

          node_name = k.chomp(':')
          assembly_node = assembly_hash_nodes.delete(node_name)

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
                    new_assembly_node_components << assembly_node_components.delete(an_cmp) if ex_cmp_name_formatted.eql?(an_cmp)
                  elsif an_cmp.is_a?(Hash)
                    an_cmp_name = an_cmp.keys.first
                    new_assembly_node_components << assembly_node_components.delete(an_cmp) if ex_cmp_name_formatted.eql?(an_cmp_name)
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
    end
  end
end; end