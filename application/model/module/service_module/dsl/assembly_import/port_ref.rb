#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class ServiceModule
  class AssemblyImport
    class PortRef < SimpleHashObject
      include ServiceDSLCommonMixin

      def self.parse(port_ref, assembly_id_or_opts = {})
        assembly_id = nil
        err_opts = Opts.new
        if assembly_id_or_opts.is_a?(Hash)
          assembly_id = assembly_id_or_opts[:assembly_id]
          err_opts.merge!(assembly_id_or_opts)
        else
          assembly_id = assembly_id_or_opts
        end

        # TODO: may need to update this to handle port refs with titles
        if port_ref =~ PortRefRegex
          node = Regexp.last_match(1); cmp_name = Regexp.last_match(2); link_def_ref = Regexp.last_match(3)
          hash = { node: node, component_type: component_type_internal_form(cmp_name), link_def_ref: link_def_ref }
          if assembly_id
            hash.merge!(assembly_id: assembly_id)
          end
          new(hash)
        else
          fail ParsingError.new("Ill-formed port ref (#{port_ref})", err_opts)
        end
      end
      def self.parse_component_link(input_node, input_cmp_name, component_link_hash, opts = {})
        err_opts = Opts.new(opts).slice(:file_path)
        unless component_link_hash.size == 1
          fail ParsingError.new('Ill-formed component link ?1', component_link_hash, err_opts)
        end
        link_def_ref = component_link_hash.keys.first

        cmp_link_value = component_link_hash.values.first
        cmp_link_value = "assembly_wide#{Seperators[:node_component]}#{cmp_link_value}" unless cmp_link_value.include?(Seperators[:node_component])

        if cmp_link_value =~ ComponentLinkTarget
          output_node = Regexp.last_match(1); output_cmp_name = Regexp.last_match(2)
          input = parsed_endpoint(input_node, input_cmp_name, link_def_ref)
          output = parsed_endpoint(output_node, output_cmp_name, link_def_ref)
          { input: input, output: output }
        else
          fail ParsingError.new("Ill-formed component link ?file_path ?1\nIt should have form: \n  ?2", component_link_hash, ComponentLinkLegalForm, err_opts)
        end
      end
      PortRefRegex = Regexp.new("(^.+)#{Seperators[:node_component]}(.+)#{Seperators[:component_link_def_ref]}(.+$)")
      ComponentLinkTarget = Regexp.new("(^.+)#{Seperators[:node_component]}(.+$)")
      ComponentLinkLegalForm = 'LinkType: Node/Component'

      # ports are augmented with field :parsed_port_name
      def matching_id(aug_ports, opts = {})
        if port_or_error = matching_port(aug_ports, opts)
          port_or_error.is_a?(ParsingError) ? port_or_error : port_or_error[:id]
        end
      end

      # ports are augmented with field :parsed_port_name
      def matching_port(aug_ports, opts = {})
        aug_ports.find { |port| matching_port__match?(port) } || matching_port__error(opts)
      end

      private

      def self.parsed_endpoint(node, cmp_name, link_def_ref)
        component_type, title = ComponentTitle.parse_component_display_name(cmp_name)
        ret_hash = { node: node, component_type: component_type_internal_form(component_type), link_def_ref: link_def_ref }
        ret_hash.merge!(title: title) if title
        new(ret_hash)
      end
      def self.component_type_internal_form(cmp_type_ext_form)
        # TODO: this does not take into account that there could be a version on cmp_type_ext_form
        InternalForm.component_ref(cmp_type_ext_form)
      end

      def matching_port__error(opts = {})
        unless opts[:do_not_throw_error]
          Error.new("Cannot find match to (#{self.inspect})")
        end

        link_def_ref  = self[:link_def_ref]
        base_cmp_name = opts[:base_cmp_name]

        opts_err = Opts.new(opts).slice(:file_path)
        if opts[:is_output]
          ParsingError::BadComponentLink::BadTarget.new(link_def_ref, base_cmp_name, target_component?, opts_err)
        else
          ParsingError::BadComponentLink::NoLinkDef.new(link_def_ref, base_cmp_name, opts_err)
        end
      end

      def target_component?
        if node = self[:node]
          if component_type = self[:component_type]
            "#{node}/#{Component.component_type_print_form(component_type)}"
          end
        end
      end

      def matching_port__match?(aug_port)
        p = aug_port[:parsed_port_name]
        node = aug_port[:node][:display_name]

        matching_port__match_on_assembly_id?(aug_port) &&
          self[:node] == node &&
          self[:component_type] == p[:component_type] &&
          self[:link_def_ref] == p[:link_def_ref] &&
          self[:title] == p[:title]
      end

      def matching_port__match_on_assembly_id?(aug_port)
        self[:assembly_id].nil? || (self[:assembly_id] == aug_port[:assembly_id])
      end

      def raise_or_ret_error(err_class, args, opts = {})
        opts_file_path = Aux.hash_subset(opts, [:file_path])
        err = err_class.new(*args, opts_file_path)
        opts[:do_not_throw_error] ? err : fail(err)
      end

      class AddOn < self
        # returns assembly ref, port_ref
        def self.parse(add_on_port_ref, assembly_list)
          assembly_name = add_on_port_ref =~ AOPortRefRegex
          port_ref = [Regexp.last_match(1), Regexp.last_match(2)]
          unless assembly_match = assembly_list.find { |a| a[:display_name] == assembly_name }
            assembly_names = assembly_list.map { |a| a[:display_name] }
            Log.error("Assembly name in add-on port link (#{assembly_name}) is illegal; must be one of (#{assembly_names.join(',')})")
            #            raise ErrorUsage.new("Assembly name in add-on port link (#{assembly_name}) is illegal; must be one of (#{assembly_names.join(',')})")
          end
          [assembly_name, super(port_ref, assembly_match[:id])]
        end
        AOSep = Seperators[:assembly_node]
        AOPortRefRegex = Regexp.new("(^[^#{AOSep}]+)#{AOSep}(.+$)")
      end
    end
  end
end; end