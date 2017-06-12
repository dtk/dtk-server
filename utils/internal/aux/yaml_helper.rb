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
require 'psych'
module DTK
  module YamlHelper
    def self.dump_simple_form(obj)
      simple_form = simple_form_aux(obj)
      # To get around Puppet monkey patch which changes YAML.dump
      #  ::YAML.dump(simple_form)
      yaml_dump(simple_form)
    end

    # opts can have keys:
    #  :file_path
    def self.parse(content, opts = {})
      ret = {}
      if content.empty?
        ret
      else
        begin
          ::YAML.load(content)
         rescue Exception => e
           ErrorUsage::Parsing::YAML.new("YAML #{e} in file", opts[:file_path], Opts.new(log_error: false))
        end
      end
    end

    private

    def self.yaml_dump(o)
      visitor = Psych::Visitors::YAMLTree.new
      visitor << o
      visitor.tree.yaml
    end

    def self.simple_form_aux(obj)
      if obj.is_a?(::Hash)
        ret = ::Hash.new
        obj.each_pair { |k, v| ret[string_form(k.to_s)] = simple_form_aux(v) }
        ret
      elsif obj.is_a?(::Array)
        obj.map { |el| simple_form_aux(el) }
      elsif obj.is_a?(::String)
        string_form(obj)
      elsif obj.is_a?(::Fixnum)
        obj
      elsif obj.is_a?(TrueClass) || obj.is_a?(FalseClass)
        obj
      elsif obj.nil?
        obj
      elsif obj.respond_to?(:to_s)
        string_form(obj.to_s)
      else
        string_form(obj.inspect)
      end
    end

    def self.string_form(str)
      if str.respond_to?(:force_encoding)
        str.dup.force_encoding(Encoding::UTF_8)
      else
        str
      end
    end
  end
end
