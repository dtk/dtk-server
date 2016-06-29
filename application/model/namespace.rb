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
module DTK
  class Namespace < Model
    # TODO: get rid of this class and fold into paraent after finish conversion
    # Methods that use this constant are:
    # - namespace_delimiter
    # - join_namespace
    # - full_module_name_parts?
    # - namespace_from_ref?
    # - module_ref_field

    NAMESPACE_DELIMITER = ':'

    def self.namespace_delimiter
      NAMESPACE_DELIMITER
    end

    def self.common_columns
      [
        :id,
        :group_id,
        :display_name,
        :name,
        :remote
      ]
    end

    # TODO: should these both be replaced by something that doed not rely on format of ref
    def self.namespace_from_ref?(service_module_ref)
      if service_module_ref.include? namespace_delimiter()
        service_module_ref.split(namespace_delimiter()).first
      end
    end

    def self.module_ref_field(module_name, namespace)
      "#{namespace}#{namespace_delimiter()}#{module_name}"
    end

    #
    # Get/Create default namespace
    #
    def self.default_namespace(namespace_mh)
      find_or_create(namespace_mh, default_namespace_name)
    end

    def self.enrich_with_default_namespace(module_name)
      module_name.include?(NAMESPACE_DELIMITER) ? module_name : "#{default_namespace_name}#{NAMESPACE_DELIMITER}#{module_name}"
    end

    # if user for some reason set R8::Config[:repo][:local][:default_namespace] to '' we will use running_process_user() as namespace
    def self.default_namespace_name
      CurrentSession.get_default_namespace() || R8::Config[:repo][:local][:default_namespace] || ::DTK::Common::Aux.running_process_user()
    end

    def self.join_namespace(namespace, name)
      "#{namespace}#{namespace_delimiter()}#{name}"
    end

    # returns [namespace,name]; namespace can be null if cant determine it
    def self.full_module_name_parts?(name_or_full_module_name)
      if name_or_full_module_name =~ Regexp.new("(^.+)#{namespace_delimiter()}(.+$)")
        namespace = Regexp.last_match(1)
        name = Regexp.last_match(2)
      else
        namespace = nil
        name = name_or_full_module_name
      end
      [namespace, name]
    end

    def self.namespace?(name_or_full_module_name)
      full_module_name_parts?(name_or_full_module_name)[0]
    end

    def self.find_by_name(namespace_mh, namespace_name)
      find_by_name?(namespace_mh, namespace_name) || fail(ErrorUsage, "Namespace '#{namespace_name}' does not exist")
    end

    def self.find_by_name?(namespace_mh, namespace_name)
      sp_hash = {
        cols: common_columns(),
        filter: [:eq, :name, namespace_name.to_s.downcase]
      }

      results = Model.get_objs(namespace_mh, sp_hash)
      fail Error, "There should not be multiple namespaces with name '#{namespace_name}'" if results.size > 1
      results.first
    end

    def self.find_or_create(namespace_mh, namespace_name)
      namespace_name = namespace_name.is_a?(Namespace) ? namespace_name.display_name : namespace_name
      fail Error, 'You need to provide namespace name where creating object' if namespace_name.nil? || namespace_name.empty?
      namespace = self.find_by_name?(namespace_mh, namespace_name)

      unless namespace
        namespace = create_new(namespace_mh, namespace_name)
      end

      namespace
    end

    def self.find_or_create_or_default(namespace_mh, namespace_name)
      namespace_obj = nil
      if (namespace_name && !namespace_name.empty?)
        namespace_obj = self.find_or_create(namespace_mh, namespace_name)
      else
        namespace_obj = self.default_namespace(namespace_mh)
      end

      namespace_obj
    end

    #
    # Create namespace object
    #
    def self.create_new(namespace_mh, name, remote = nil)
      idh = create_from_rows(namespace_mh,
                             [{
                               name: name,
                               display_name: name,
                               ref: name,
                               remote: remote
                             }]
                            ).first

      idh.create_object()
    end

    # TODO: would need to enhance if get a legitimate key, but it has nil or false value
    def method_missing(m, *args, &block)
      get_field?(m) || super(m, *args, &block)
    end
  end
end
