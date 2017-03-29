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
  module ModuleUtils
    class ListMethod
      DEFAULT_VERSION = 'CURRENT'
      MASTER_VERSION = 'master'

      def self.aggregate_detail(branch_module_rows, project_idh, model_type, opts)
        project = project_idh.create_object()
        module_mh = project_idh.createMH(model_type)
        diff       = opts[:diff]
        remote_repo_base = opts[:remote_repo_base]
        if opts[:include_remotes]
          augment_with_remotes_info!(branch_module_rows, module_mh)
        end
        # if there is an external_ref source, use that otherwise look for remote dtkn
        # there can be duplictes for a module when multiple repos; in which case will agree on all fields
        # except :repo, :module_branch, and :repo_remotes
        # index by module
        ndx_ret = {}
        # aggregate
        branch_module_rows.each do |r|
          module_branch    = r[:module_branch]
          module_name      = r.module_name()
          ndx_repo_remotes = r[:ndx_repo_remotes]
          repo             = r[:repo]
          ndx = r[:id]
          is_equal = nil
          not_published = nil

          unless mdl = ndx_ret[ndx]
            r.delete(:repo)
            r.delete(:module_branch)
            mdl = ndx_ret[ndx] = r
          end

          # if finding differences with the dtkn catalog
          if diff && module_branch[:version].eql?('master')
            if default_remote_repo = RepoRemote.default_repo_remote?((ndx_repo_remotes || {}).values)
              remote = default_remote_repo.remote_dtkn_location(project, model_type, module_name)
              is_equal = repo.ret_local_remote_diff(module_branch, remote)
            elsif default_remote_repo = RepoRemote.default_from_module_branch?(module_branch)
              remote = default_remote_repo.remote_dtkn_location(project, model_type, module_name)
              is_equal = repo.ret_local_remote_diff(module_branch, remote)
            else
              not_published = true
            end

            mdl.merge!(remote_relationship: is_equal)
            mdl.merge!(not_published: not_published)
          end

          if opts[:include_versions]
            version = module_branch.version_print_form(Opts.new(default_version_string: MASTER_VERSION))
            unless version.eql?('CURRENT')
              version_print = r[:dsl_parsed] ? version : "*#{version}"
              (mdl[:version_array] ||= []) << version_print
            end
          end
          if external_ref_source = module_branch.external_ref_source()
            mdl[:external_ref_source] = external_ref_source
          end
          if ndx_repo_remotes
            ndx_repo_remotes.each do |remote_repo_id, remote_repo|
              (mdl[:ndx_repo_remotes] ||= {})[remote_repo_id] ||= remote_repo
            end
          end
        end
        # put in display name form
        ndx_ret.each_value do |mdl|
          if raw_va = mdl.delete(:version_array)
            if raw_va.size == 1
              mdl.merge!(versions: raw_va[0])
            else
              version_array = []
              master_print  = raw_va.find { |v| v.delete('*') == MASTER_VERSION }
              raw_va.delete(master_print)

              version_array << master_print if master_print
              version_array << raw_va.sort{ |a, b| a.delete('*') <=> b.delete('*') }.reverse

              mdl.merge!(versions: version_array.join(', '))
            end
          end

          external_ref_source = mdl.delete(:external_ref_source)
          ndx_repo_remotes = mdl.delete(:ndx_repo_remotes)

          if linked_remote = linked_remotes_print_form((ndx_repo_remotes || {}).values, external_ref_source, not_published: mdl[:not_published])
            mdl.merge!(linked_remotes: linked_remote)
          end
        end
        ndx_ret.values
      end

      # each branch_module_row has a nested :repo column
      def self.augment_with_remotes_info!(branch_module_rows, module_mh)
        # index by repo_id
        ndx_branch_module_rows = branch_module_rows.inject({}) { |h, r| r[:repo] ? h.merge(r[:repo][:id] => r) : h }
        unless ndx_branch_module_rows.empty?
          sp_hash = {
            cols: [:id, :group_id, :display_name, :repo_id, :repo_name, :repo_namespace, :created_at, :is_default],
            filter: [:oneof, :repo_id, ndx_branch_module_rows.keys]
          }

          remotes = Model.get_objs(module_mh.createMH(:repo_remote), sp_hash)

          remotes.each do |r|
            ndx = r[:repo_id]
            (ndx_branch_module_rows[ndx][:ndx_repo_remotes] ||= {}).merge!(r[:id] => r)
          end
        end
      end

      def self.linked_remotes_print_form(repo_remotes, external_ref_source, opts = {})
        opts_pp = Opts.new(provider_prefix: true)
        array =
          if repo_remotes.empty?
            []
          elsif repo_remotes.size == 1
            [repo_remotes.first.print_form(opts_pp)]
          else
            if default = RepoRemote.default_repo_remote?(repo_remotes)
              # remove all non default dtkn_providers
              repo_remotes.reject! { |r| r[:id] == default[:id] and r.is_dtkn_provider? }
              [default.print_form(opts_pp)] + repo_remotes.map { |r| r.print_form(opts_pp) }
            else
              repo_remotes.map { |r| r.print_form(opts_pp) }
            end
          end

        array << external_ref_source if external_ref_source
        array << '*** NOT PUBLISHED in DTKN ***' if opts[:not_published]

        array.uniq.join(JoinDelimiter)
      end
      JoinDelimiter = ', '
    end
  end
end
