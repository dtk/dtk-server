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
module DTK; class Node
  class Template
    class Factory < self
      def self.create_or_update(target, node_template_name, image_id, opts = {})
        # TODO: DTK-2489: removed after move to target service instance
        # raise_error_if_invalid_image(image_id, target)
        raise_error_if_invalid_os(opts[:operating_system])
        size_array = raise_error_if_invalid_size_array(opts[:size_array])

        hash_content = {
          node: {},
          node_binding_ruleset: {}
        }
        size_array.each do |size|
          factory = new(target, node_template_name, image_id, size, opts)
          nbrs_factory = NodeBindingRuleset::Factory.new(factory)

          hash_content[:node_binding_ruleset].merge!(nbrs_factory.create_or_update_hash())
          hash_content[:node].merge!(factory.node_template(nbrs_factory))
        end

        public_library_idh = get_public_library(target.model_handle()).id_handle()
        Model.import_objects_from_hash(public_library_idh, hash_content)
      end

      attr_reader :target, :image_id, :os_identifier, :os_type, :size

      def initialize(target, os_identifier, image_id, size, opts = {})
        @target = target
        @image_id = image_id
        @os_identifier = os_identifier
        @os_type = opts[:operating_system]
        @size = size
      end

      def node_template(nbrs_factory)
        hash_body = {
          :os_type => @os_type,
          :os_identifier => @os_identifier,
          :type => 'image',
          :display_name => node_template_display_name(),
          :external_ref => {
            image_id: @image_id,
            type: node_template_type(),
            size: @size
          },
          :attribute => {
            'host_addresses_ipv4' => NodeAttribute::DefaultValue.host_addresses_ipv4(),
            'fqdn' => NodeAttribute::DefaultValue.fqdn(),
            'node_components' => NodeAttribute::DefaultValue.node_components()
          },
          :node_interface => { 'eth0' => { type: 'ethernet', display_name: 'eth0' } },
          '*node_binding_rs_id' => "/node_binding_ruleset/#{nbrs_factory.ref()}"
        }
        { node_template_ref() => hash_body }
      end

      private

      def self.raise_error_if_invalid_os(os)
        if os.nil?
          fail ErrorUsage.new('Operating system must be given')
        end
        os = os.to_sym
        unless LegalOSs.include?(os)
          fail ErrorUsage.new("OS parameter (#{os}) is invalid; legal values are: #{LegalOSs.join(', ')}")
        end
        os
      end
      # TODO: sync with ../utils/internal/command_and_control/install_script.rb OSTemplates keys
      LegalOSs = %w{ubuntu redhat centos debian amazon-linux}.map { |os| os.to_sym }

      def self.raise_error_if_invalid_size_array(size_array)
        size_array ||= ['t1.micro'] #TODO: stub
        if size_array.nil?
          fail ErrorUsage.new('One or more image sizes must be given')
        end
        size_array
      end

      def node_template_ref
        "#{@image_id}-#{@size}"
      end

      def node_template_display_name
        "#{@os_identifier} #{@size}"
      end

      def node_template_type
        Template.image_type(@target)
      end
    end
  end
end; end
