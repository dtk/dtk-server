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
module DTK; class LinkDef
  module ParseSerializedFormClassMixin
    def parse_serialized_form_local(link_defs, config_agent_type, remote_link_defs, local_cmp_ref = nil)
      ParseSerializedForm.new(config_agent_type, remote_link_defs, local_cmp_ref).parse(link_defs)
    end

    # This is used to convert from add hoc link commands into internal form
    def parse_serialized_form_attribute_mapping(mapping)
      ParseSerializedForm.new().parse_possible_link_attribute_mapping(mapping)
    end

    def parse_from_create_dependency(link_def)
      ParseSerializedForm.new().parse([link_def])
    end
  end

  class ParseSerializedForm
    attr_reader :config_agent_type, :remote_link_defs, :local_cmp_ref
    def initialize(config_agent_type = nil, remote_link_defs = {}, local_cmp_ref = nil)
      @config_agent_type = config_agent_type
      @remote_link_defs = remote_link_defs
      @local_cmp_ref = local_cmp_ref
    end

    def parse(link_defs)
      link_defs.inject({}) do |h, link_def|
        link_def_type = link_def['type']
        ref = "local_#{link_def_type}"
        has_external_internal = { #defaults that can be overritten
          has_internal_link: false,
          has_external_link: false
        }
        possible_links = parse_possible_links_local(link_def['possible_links'], link_def_type, has_external_internal)
        el = {
          display_name: ref,
          local_or_remote: 'local',
          link_type: link_def_type,
          link_def_link: possible_links
        }.merge(has_external_internal)
        el.merge!(required: link_def['required']) if link_def.key?('required')
        el.merge!(description: link_def['description']) if link_def.key?('description')
        h.merge(ref => el)
      end
    end

    private

    def parse_possible_links_local(possible_links, link_def_type, has_external_internal)
      position = 0
      possible_links.inject({}) do |h, possible_link|
        remote_component_type = possible_link.keys.first
        possible_link_info = possible_link.values.first
        possible_link_type = possible_link_info['type']

        add_remote_link_def?(remote_link_defs, remote_component_type, link_def_type, possible_link_type)

        has_external_internal[:has_internal_link] = true if %w(internal internal_external).include?(possible_link_type)
        has_external_internal[:has_external_link] = true if %w(external internal_external).include?(possible_link_type)

        position += 1
        ref = "#{remote_component_type}___#{position}" #to make sure unqiue for case when same remote type
        el = {
          display_name: remote_component_type,
          remote_component_type: remote_component_type,
          position: position,
          content: parse_possible_link_content(possible_link_info),
          type: possible_link_type
        }
        if order = possible_link_info['order']
          el.merge!(temporal_order: order)
        end
        h.merge(ref => el)
      end
    end

    def add_remote_link_def?(remote_link_defs, remote_component_type, link_def_type, possible_link_type)
      pointer = remote_link_defs[remote_component_type] ||= {}
      ref = "remote_#{link_def_type}"
      pointer[ref] ||= {
        display_name: ref,
        config_agent_type: config_agent_type,
        local_or_remote: 'remote',
        link_type: link_def_type
      }
      pointer[ref][:has_internal_link] = true if %w(internal internal_external).include?(possible_link_type)
      pointer[ref][:has_external_link] = true if %w(external internal_external).include?(possible_link_type)
      if local_cmp_ref && pointer[ref][:has_external_link]
        pointer[ref].merge!(local_cmp_ref: local_cmp_ref)
      end
    end

    def parse_possible_link_content(possible_link)
      ret = {}
      events = possible_link['events'] || []
      events.each do |evs|
        parsed_evs = parse_possible_link_on_create_events(evs)
        (ret[:events] ||= {}).merge!(parsed_evs) if parsed_evs
      end

      attribute_mappings = possible_link['attribute_mappings'] || []
      constraints = possible_link['constraints'] || []
      preferences = possible_link['preferences'] || []

      unless attribute_mappings.empty?
        ret[:attribute_mappings] = attribute_mappings.map { |am| parse_possible_link_attribute_mapping(am) }
      end

      unless constraints.empty?
        ret[:constraints] = constraints
      end

      unless preferences.empty?
        ret[:preferences] = preferences
      end

      ret
    end

    def parse_possible_link_attribute_mapping(mapping)
      {
        output: parse_attribute_term(mapping.keys.first),
        input: parse_attribute_term(mapping.values.first)
      }
    end
    public :parse_possible_link_attribute_mapping

    def parse_possible_link_on_create_events(events)
      trigger = events.first
      case trigger
      when 'on_create_link'
        { on_create: parse_events(events[1]) }
      else
        Log.error("unexpected event trigger: #{trigger}")
        nil
      end
    end

    def parse_events(events)
      ret = []
      events.each do |ev|
        ev_type = ev.keys.first
        ev_content = ev.values.first
        case ev_type
         when 'extend_component'
          parsed_ev = parse_event_extend_component(ev_content)
          ret << parsed_ev if parsed_ev
         else
          Log.error("unexpected event type: #{ev_type}")
        end
      end
      ret
    end

    def parse_event_extend_component(ev_content)
      remote_or_local = ev_content[:node] || :remote
      ret = {
        event_type: 'extend_component',
        node: remote_or_local,
        extension_type: ev_content['extension_type']
      }
      ret.merge!(alias: ev_content['alias']) if ev_content.key?('alias')
      ret
    end

    # returns node_name, component_name, attribute_name, path; where component_name xor node_name is null depending on whether it is a node or component attribute
    def parse_attribute_term(term_x)
      ret = {}
      term = term_x.to_s.gsub(/^:/, '')
      ret[:term_index] = term
      split = term.split(SplitPat)

      if split[0] =~ NodeTermRE
        ret[:type] = 'node_attribute'
        ret[:node_name] = Regexp.last_match(1)
      elsif split[0] =~ ComponentTermRE
        ret[:type] = 'component_attribute'
        ret[:component_type] = Regexp.last_match(1)
      else
        fail Error.new("unexpected form (#{term_x.inspect})")
      end

      unless split.size > 1
        fail Error.new("unexpected form (#{term_x.inspect})")
      end
      if split[1] =~ AttributeTermRE
        ret[:attribute_name] = Regexp.last_match(1)
      # ABC
      elsif split[1] =~ /\$\{(.+)\}/
        ret[:attribute_name] = Regexp.last_match(1)
      else
        fail Error.new("unexpected form (#{term_x.inspect})")
      end

      if split.size > 2
        ret[:path] = split[2, split.size - 2]
      end
      ret
    end

    SimpleTokenPat = 'a-zA-Z0-9_-'
    SplitPat = '.'

    NodeTermRE = Regexp.new('^(local|remote)_node$')
    ComponentTermRE = Regexp.new("^([#{SimpleTokenPat}]+$)")
    AttributeTermRE = Regexp.new("^([#{SimpleTokenPat}]+$)")
  end
end; end