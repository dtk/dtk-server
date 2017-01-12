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

module DTK
  class Component
    # Class and isntance method for displaying component related names
    # TODO: might split into component instance and component template specfic methods
    module Name
      module ClassMixin
        COMPONENT_TYPE_DELIM = '__'
        DISPLAY_NAME_DELIM = '::'
        NAMESPACE_DELIM = ':'
        
        def display_name_from_user_friendly_name(user_friendly_name)
          # using sub instead of gsub because we need only first :: to change to __
          # e.g. we have cmp "mysql::bindings::java" we want "mysql__bindings::java"
          user_friendly_name.sub(Regexp.new(DISPLAY_NAME_DELIM), COMPONENT_TYPE_DELIM)
        end
        
        def name_with_version(name, version)
          if version.is_a?(ModuleVersion::Semantic)
            "#{name}(#{version})"
          else
            name
          end
        end
        
        def ref_with_version(ref, version)
          "#{ref}__#{version}"
        end
        
        def component_type_from_module_and_component(module_name, component_part)
          if module_name == component_part
            component_part
          else
            "#{module_name}#{COMPONENT_TYPE_DELIM}#{component_part}"
          end
        end
        
        def component_type_from_user_friendly_name(user_friendly_component_name)
          # the part .split('[').first strips off title if it is there
          user_friendly_component_name.sub(Regexp.new(DISPLAY_NAME_DELIM), COMPONENT_TYPE_DELIM).split('[').first 
        end
        
        def module_name(component_type)
          component_type.split(COMPONENT_TYPE_DELIM).first
        end


        def display_name_print_form(display_name, opts = {})
          ret = component_type_print_form(display_name, opts)

          if namespace = opts[:namespace]
            ret = "#{namespace}#{NAMESPACE_DELIM}#{ret}"
          end
          
          if version = opts[:version]
            ret = "#{ret}(#{version})" unless version.eql?('master')
          end
          
          ret
        end

        def component_type_print_form(component_type, opts = {})
          if opts[:no_module_name]
            component_type.gsub(Regexp.new("^.+#{COMPONENT_TYPE_DELIM}"), '')
          else
            component_type.gsub(Regexp.new(COMPONENT_TYPE_DELIM), DISPLAY_NAME_DELIM)
          end
        end
        
      end

      module Mixin
        def display_name_print_form(opts = {})
          cols_to_get = [:component_type, :display_name]
          unless opts[:without_version]
            cols_to_get += [:version]
          end
          update_object!(*cols_to_get)
          component_type = component_type_print_form()
          
          # handle version
          ret =
            if opts[:without_version] || has_default_version?()
              component_type
            else
              self.class.name_with_version(component_type, self[:version])
            end
          
          # handle component title
          if title = ComponentTitle.title?(self)
            ret = ComponentTitle.print_form_with_title(ret, title)
          end
          
          if opts[:namespace_prefix]
            if cmp_namespace = self[:namespace]
              ret = "#{cmp_namespace}:#{ret}"
            end
          end
          
          if opts[:node_prefix]
            if node = get_node()
              ret = "#{node[:display_name]}/#{ret}"
            end
          end
          ret
        end
        
        def component_type_print_form
          Component.component_type_print_form(get_field?(:component_type))
        end
        
        def convert_to_print_form!
          update_object!(:display_name, :version)
          component_type = component_type_print_form()
          
          opts = { namespace: self[:namespace] }
          opts.merge!( version: self[:version] ) unless has_default_version?()
          self[:display_name] = Component.display_name_print_form(self[:display_name], opts)
          
          self[:version] = nil if has_default_version?()
          self
        end
        
      end
      
    end
  end
end
