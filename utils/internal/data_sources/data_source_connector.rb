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
module XYZ
  module DSConnector
    class Top
      def initialize(container_uri)
        @container_uri = container_uri
        initialize_extra()
      end
      # this can be overwritten
      def initialize_extra
      end

      def get_objects(obj_type, source_obj_type, &block)
        method_name = "get_objects__#{obj_type}#{source_obj_type ? '__' + source_obj_type : ''}".to_sym
        send(method_name) { |source_obj| block.call(source_obj) }
      end
    end
  end
  module DataSourceConnectorInstanceMixin
    def set_and_share_ds_connector!(common_ds_connectors, container_uri)
      common_ds_connectors[container_uri] ||= {}
      common_ds_connectors[container_uri][@ds_connector_class] ||= @ds_connector_class.new(container_uri)
      @ds_connector_instance = common_ds_connectors[container_uri][@ds_connector_class]
    end

    private

    def load_ds_connector_class
      rel_path = "#{ds_name()}/#{ds_name()}"
      begin
        file_path = File.expand_path(rel_path, File.dirname(__FILE__))
        require file_path
       rescue Exception => e
        raise Error.new("Connector file to process object data source #{ds_name()} does not exist") unless File.exist?(file_path + '.rb')
        raise e
      end

      @ds_connector_class = DSConnector.const_get Aux.camelize(ds_name())
    end

    def get_objects(&block)
      @ds_connector_instance.get_objects(obj_type(), source_obj_type(), &block)
    end
  end
end