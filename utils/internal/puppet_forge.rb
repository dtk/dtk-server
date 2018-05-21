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
  module PuppetForge
    # require_relative('puppet_forge/client')
    # require_relative('puppet_forge/local_copy')

    # # user and name sepparator used by puppetforge
    # MODULE_NAME_SEPARATOR = '-'

    # # returns [pf_namespace,pf_module_name]
    # def self.puppet_forge_namespace_and_module_name(pf_module_name)
    #   pf_module_name.split(MODULE_NAME_SEPARATOR, 2)
    # end

    # def self.puppet_forge_module_name(pf_module_name)
    #   puppet_forge_namespace_and_module_name(pf_module_name).last
    # end

    # def self.index(namespace, name)
    #   "#{namespace}-#{name}"
    # end

    # class Module
    #   attr_reader :path, :name, :is_dependency
    #   attr_accessor :namespace, :dependencies, :id

    #   def initialize(hash, is_dependency = false, type = :component_module, dtk_version = nil)
    #     m_namespace, m_name = PuppetForge.puppet_forge_namespace_and_module_name(hash['module'])

    #     @name          = m_name
    #     @namespace     = m_namespace
    #     @is_dependency = is_dependency
    #     @type          = type
    #     @dtk_version   = dtk_version
    #     @module        = hash['module']
    #     @version       = hash['version']
    #     @file          = hash['file']
    #     @path          = "#{hash['path']}/#{PuppetForge.puppet_forge_module_name(@module)}"
    #     @dependencies  = []
    #     @id            = nil
    #   end

    #   def index
    #     PuppetForge.index(@namespace, @name)
    #   end

    #   def default_local_module_name
    #     PuppetForge.puppet_forge_module_name(@module)
    #   end

    #   def set_id(id)
    #     @id = id
    #   end

    #   def module_source_name
    #     @module
    #   end

    #   def to_h
    #     {
    #       name: @name,
    #       namespace: @namespace,
    #       version: @dtk_version,
    #       type: @type,
    #       id: @id
    #     }
    #   end
    # end
  end
end
