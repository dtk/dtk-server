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
module DTK; class Clone
  class ChildContext < SimpleHashObject
    r8_nested_require('child_context', 'assembly_node')
    r8_nested_require('child_context', 'assembly_node_attribute')
    r8_nested_require('child_context', 'port_link')
    r8_nested_require('child_context', 'assembly_component_ref')
    r8_nested_require('child_context', 'assembly_component_attribute')
    def clone_copy_child_objects(clone_proc, level)
      clone_model_handle = clone_model_handle()
      field_set_to_copy = ret_field_set_to_copy()
      fk_info = clone_proc.fk_info
      fk_info.add_foreign_keys(clone_model_handle, field_set_to_copy)
      create_override_attrs = clone_proc.ret_real_columns(clone_model_handle, override_attrs)
      new_objs_info = ret_new_objs_info(field_set_to_copy, create_override_attrs)
      return if new_objs_info.empty?

      new_id_handles = clone_proc.add_new_children_objects(new_objs_info, clone_model_handle, clone_par_col, level)
      fk_info.add_id_mappings(clone_model_handle, new_objs_info)
      fk_info.add_id_handles(new_id_handles) #TODO: may be more efficient adding only id handles assciated with foreign keys

      # iterate all nested children
      opts_generate = {}
      if include_list = include_list()
        opts_generate.merge!(include_list: include_list)
      end
      self.class.generate(clone_proc, clone_model_handle, new_objs_info, override_attrs, opts_generate) do |child_context|
        child_context.clone_copy_child_objects(clone_proc, level + 1)
      end
    end

    def self.generate(clone_proc, model_handle, unpruned_objs_info, recursive_override_attrs, opts = {}, &block)
      ret = []
      opts_generate = Aux.hash_subset(opts, [:include_list])
      get_children_model_handles(model_handle, opts_generate) do |child_mh|
        child_mn = child_mh[:model_name]
        objs_info = unpruned_objs_info.reject { |r| r[:donot_clone] && r[:donot_clone].include?(child_mn) }
        next if objs_info.empty?

        override_attrs = clone_proc.ret_child_override_attrs(child_mh, recursive_override_attrs)
        parent_id_col = child_mh.parent_id_field_name()
        old_parent_rel_col = ret_old_parent_rel_col(clone_proc, child_mh)
        parent_rels = objs_info.map do |row|
          if old_par_id = row[old_parent_rel_col]
            { parent_id_col => row[:id], :old_par_id => old_par_id }
          else
            fail Error.new("Column (#{old_parent_rel_col}) not found in objs_info")
          end
        end
        child_context_hash = {
          model_handle: child_mh,
          clone_par_col: parent_id_col,
          parent_rels: parent_rels,
          override_attrs: override_attrs,
          create_opts: {
            duplicate_refs: :no_check,
            returning_sql_cols: returning_sql_cols(parent_id_col)
          },
          parent_objs_info: objs_info
        }
        opts_x = Aux.hash_subset(opts, [:standard_child_context])
        child_context = create_from_hash(clone_proc, child_context_hash, opts_x)
        if block
          block.call(child_context)
        else
          ret << child_context
        end
      end
      ret unless block
    end

    # parent_links has type InstanceTemplate::Links
    def self.create_from_parent_links(template_child_idhs, parent_links)
      if template_child_idhs.empty? || parent_links.empty?
        fail Error.new('Should not be called with template_child_idhs.empty? or parent_links.empty?')
      end
      child_mh = template_child_idhs.first.createMH()
      parent_id_col = child_mh.parent_id_field_name()
      parent_rels = parent_links.parent_rels(child_mh)

      hash = {
        model_handle: child_mh,
        clone_par_col: parent_id_col,
        parent_rels: parent_rels,
        where_clause: { id: template_child_idhs.map(&:get_id) },
        create_opts: {
          duplicate_refs: :no_check,
          returning_sql_cols: returning_sql_cols(parent_id_col)
        }
      }
      clone_proc = nil
      new(clone_proc, hash)
    end

    #instance_template_links has type InstanceTemplate::Links
    def self.modify_instances(model_handle, instance_template_links)
      parent_id_col = model_handle.parent_id_field_name()
      concrete_model_name = Model.concrete_model_name(model_handle[:model_name])
      field_set = Model::FieldSet.all_real(concrete_model_name).with_removed_cols(:id, :local_id, parent_id_col)

      base_fs = Model::FieldSet.opt(field_set.cols + [{ id: :template_id }], model_handle[:model_name])
      base_wc = SQL.in(:id, instance_template_links.templates.map(&:id))
      base_ds = Model.get_objects_just_dataset(model_handle, base_wc, base_fs)

      mappping_rows = instance_template_links.map do |l|
        { id: l.instance.id, template_id: l.template.id }
      end
      mapping_mh = model_handle.createMH(:mappings)
      mapping_ds = array_dataset(model_handle.db(), mappping_rows, mapping_mh)

      select_ds = base_ds.join_table(:inner, mapping_ds, [:template_id])
      field_set_to_update = field_set.with_removed_cols(:ancestor_id, parent_id_col)
      Model.update_from_select(model_handle, field_set_to_update, select_ds)
    end

    def create_new_objects
      create_override_attrs = {}
      ret_new_objs_info(ret_field_set_to_copy(), create_override_attrs)
    end

    def self.returning_sql_cols(parent_id_col)
      [:ancestor_id, parent_id_col]
    end

    def self.create_from_hash(clone_proc, hash, opts = {})
      if opts[:standard_child_context]
        return new(clone_proc, hash)
      end
      unless clone_proc.cloning_assembly?()
        return new(clone_proc, hash)
      end

      model_name = Model.normalize_model(hash[:model_handle][:model_name])
      parent_model_name = Model.normalize_model(hash[:model_handle][:parent_model_name])
      klass = ret_special_child_context?(clone_proc, parent_model_name, model_name) || ChildContext
      klass.new(clone_proc, hash)
    end

    private

    #this can be over-written
    def include_list
      nil
    end

    def self.ret_special_child_context?(clone_proc, parent_model_name, model_name)
      if match = (SpecialContext[clone_proc.clone_direction()][parent_model_name] || {})[model_name]
        if match.is_a?(Proc)
          match.call(clone_proc)
        else
          match
        end
      end
    end
    # index are clone_direction, parent, child
    SpecialContext = {
      library_to_target: {
        target: {
          node: AssemblyNode,
          port_link: PortLink
        },
        node: {
          attribute: AssemblyNodeAttribute,
          component_ref: AssemblyComponentRef
        },
        component: {
          attribute: AssemblyComponentAttribute
        }
      },
      # TODO: remove; since using different mechanism to save an assembly instance in the library
      target_to_library: {
        #:library => {:node => AssemblyTemplateNode},
        #:node => {:component => AssemblyTemplateComponent}
      }
    }


    def initialize(clone_proc, hash)
      super(hash)
      @clone_proc = clone_proc
    end

    def db
      # TODO: could probably simplify this to model_handle.db()
      (@clone_proc && @clone_proc.db()) || model_handle.db()
    end

    def self.get_children_model_handles(model_handle, opts = {}, &block)
      include_list = opts[:include_list]
      model_handle.get_children_model_handles(clone_context: true).each do |child_mh|
        if include_list
          next unless include_list.include?(child_mh[:model_name])
        end
        block.call(child_mh)
      end
    end

    def ret_field_set_to_copy
      Model::FieldSet.all_real(clone_model_handle[:model_name]).with_removed_cols(:id, :local_id)
    end

    def ret_new_objs_info(field_set_to_copy, create_override_attrs)
      ancestor_rel_ds = array_dataset(parent_rels, :target)
      # all parent_rels will have same cols so taking a sample
      remove_cols = [:ancestor_id] + parent_rels.first.keys.reject { |col| col == :old_par_id }
      field_set_from_ancestor = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols({ id: :ancestor_id }, clone_par_col => :old_par_id)

      wc = self[:where_clause]
      ds = Model.get_objects_just_dataset(model_handle, wc, Model::FieldSet.opt(field_set_from_ancestor))

      select_ds = ancestor_rel_ds.join_table(:inner, ds, [:old_par_id])
      Model.create_from_select(model_handle, field_set_to_copy, select_ds, create_override_attrs, create_opts)
    end

    def array_dataset(rows, model_name)
      self.class.array_dataset(db(), rows, model_handle.createMH(model_name))
    end
    def self.array_dataset(db, rows, model_handle)
      SQL::ArrayDataset.create(db, rows, model_handle)
    end

    def self.ret_old_parent_rel_col(clone_proc, model_handle)
      ret = :ancestor_id
      unless clone_proc.cloning_assembly? && clone_proc.clone_direction() == :library_to_target
        return ret
      end

      model_name = Model.normalize_model(model_handle[:model_name])
      parent_model_name = Model.normalize_model(model_handle[:parent_model_name])
      if parent_model_name == :node and not [:component_ref, :port].include?(model_name)
        :node_template_id
      else
        ret
      end
    end

    def parent_rels
      self[:parent_rels]
    end

    def model_handle
      self[:model_handle]
    end

    # can differ such as for component_ref
    # can be over written
    def clone_model_handle
      model_handle()
    end

    def clone_par_col
      self[:clone_par_col]
    end

    def override_attrs
      self[:override_attrs]
    end

    def create_opts
      self[:create_opts]
    end

    def matches
      self[:matches]
    end

    def parent_objs_info
      self[:parent_objs_info]
    end
  end
end; end
