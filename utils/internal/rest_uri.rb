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
  module RestURI
    class << self
      def parse_factory_uri(factory_uri)
        if factory_uri =~ %r{(.*)/(.+)}
          parent_uri = Regexp.last_match(1) == '' ? '/' : Regexp.last_match(1)
          relation_type = Regexp.last_match(2).to_sym

    fail Error.new("invalid relation type '#{relation_type}'") if DB_REL_DEF[relation_type].nil?
          [relation_type, parent_uri]
        else
    fail Error.new("factory_uri (#{factory_uri}) in incorrect form")
        end
      end

      # TBD: for some or all these fns wil be useful to have a variant that deals with id_handles
      def parse_instance_uri(instance_uri)
        instance_uri =~ %r{(.*)/(.+)} ?
          # instance_ref,factory_uri
          [Regexp.last_match(2), Regexp.last_match(1)] : nil
      end

      def ret_top_container_relation_type(uri)
        uri =~ %r{^/([^/]+)}
        Regexp.last_match(1).to_sym
      end

      def ret_top_container_uri(uri)
        uri =~ %r{^(/[^/]+/[^/]+)/}
        Regexp.last_match(1)
      end

      def ret_relation_type_from_instance_uri(instance_uri)
        instance_ref, factory_uri = parse_instance_uri(instance_uri)
        return nil if factory_uri.nil?
        relation_type, parent_uri = parse_factory_uri(factory_uri)
        relation_type
      end

      def ret_factory_uri(parent_uri, relation_type)
        parent_uri + '/' + relation_type.to_s
      end

      def ret_new_uri(factory_uri, ref, ref_num)
        qualified_ref = ref.to_s + (ref_num ? '-' + ref_num.to_s : '')
        ret_child_uri_from_qualified_ref(factory_uri, qualified_ref)
      end

      def ret_child_uri_from_qualified_ref(factory_uri, qualified_ref)
        factory_uri + '/' + qualified_ref.to_s
      end
    end
  end
end