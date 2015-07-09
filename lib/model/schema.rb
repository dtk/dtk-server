
# TODO: move these to admin functions and lose notion of schema/data for the core model
# Core model should be just everything that is universal to interact with objects including
# base field defs for id,date_created/modified, created_by user, modified_user, etc

require File.expand_path('schema/migration_methods', File.dirname(__FILE__))
module DTK
  # class methods
  # TODO: partition into public and private
  module ModelSchemaClassMixins
    def set_relation_as_top
      @is_top = true
    end

    def top?
      @is_top
    end

    def set_relation_name(*arg)
      @is_top = nil
      @relation_type = ret_relation_type(self)
      @db_rel = convert_to_db_rel_form(*arg)
      @db_rel[:relation_type] = @relation_type
      @db_rel[:many_to_one] = []
      @db_rel[:one_to_many] = []
      @db_rel[:one_to_many_clone_omit] = []
      @db_rel[:columns] = {}
      @db_rel[:virtual_columns] = {}
      @db_rel[:model_class] = self
    end

    def up
      model_def = load_model_def()
      return unless model_def

      relation_name_info = [model_def[:schema]].compact + [model_def[:table]]
      set_relation_name(*relation_name_info)
      model_def.each { |k, v| @db_rel[k] = v }
    end

    def set_submodel(submodel_name)
      if model_def = load_model_def(submodel_name)
        model_def.each do |top_key, top_val|
          next unless [:virtual_columns].include?(top_key)
          top_val.each { |k, v| @db_rel[top_key][k] = v }
        end
      end
    end

    private

    def load_model_def(model_nm = model_name())
      # special case: base_module is superclass for modules (component_module, test_module, etc.)
      return if model_nm == :base_module

      model_def_fn = "#{R8::Config[:meta_templates_root]}/#{model_nm}/new/model_def.rb"
      fail Error.new("cannot find model def file #{model_def_fn} for #{model_name()}") unless  File.exists?(model_def_fn)
      begin
        eval(IO.read(model_def_fn))
       rescue Exception => e
        raise Error.new("parsing error in #{model_def_fn}: #{e.inspect}")
      end
    end

    public

    def db_rel
      @db_rel ||= (superclass.respond_to?(:db_rel) && superclass.db_rel())
    end

    def many_to_one(*target_relation_types)
      @db_rel[:many_to_one] = target_relation_types
    end

    def one_to_many(*target_relation_types)
      @db_rel[:one_to_many] = target_relation_types
    end

    def one_to_many_clone_omit(*target_relation_types)
      @db_rel[:one_to_many_clone_omit] = target_relation_types
    end

    def column(col_name, col_type, opts = {})
      @db_rel[:columns][col_name] = { type: col_type }.merge(opts)
    end

    def virtual_column(col_name, opts = {})
      @db_rel[:virtual_columns][col_name] = opts
    end

    # TODO: hardwired to ref column id on target table
    def foreign_key(col_name, target_rel_type, opts = {})
      @db_rel[:columns][col_name] = { type: ID_TYPES[:id], foreign_key_rel_type: target_rel_type }.merge(opts)
      CloneHelper.add_foreign_key_info(@relation_type, col_name, target_rel_type)
    end

    def has_ancestor_field
      @db_rel[:has_ancestor_field] = true
      foreign_key(:ancestor_id, @relation_type, FK_SET_NULL_OPT)
    end

    def ret_relation_type(klass)
      model_name_helper(klass, no_subclass: true)
    end

    #------common column defs -----------
    # for external refs
    def external_ref_column_defs
      column :external_ref, :json
    end

    # for data source attributes
    def ds_column_defs(*names)
      names.each { |n| ds_column_def(n) }
    end

    def ds_column_def(name)
      if name == :ds_attributes
        column :ds_attributes, :json
      elsif  name == :ds_key
        # TODO: should this be commented out?: :default => '' so when do 'prune inventory' this column not null
        column :ds_key, :varchar, default: '', hidden: true
      elsif  name == :data_source
        column :data_source, :varchar, size: 25
      elsif  name == :ds_source_obj_type
        column :ds_source_obj_type, :varchar, size: 25
      end
    end
    #------common column defs -----------
    include MigrationMethods

      # gets over written for classes with data source attributes
      def ds_attributes(attr_list)
       attr_list
      end
      # gets over written for classes that restrict children
      def is_ds_subobject?(_relation_type)
        true
      end

      def set_db_for_specfic_models(db, model_names)
        set_db_for_all_models(db, model_names)
      end

      def set_db_for_all_models(db, filter = nil)
        Model.set_db(db)
        models =
          if filter
            filter.map { |model_name| Model.model_class(model_name) }
          else
            models()
          end
        models.each { |model| model.set_db(db) } #TODO: see if we can remove needing to link all children of Model
        # infra tables
        ContextTable.set_db(db)
        IDInfoTable.set_db(db)
      end

      def setup_infrastructure_tables?(db)
        ContextTable.create?()
        ContextTable.create_default_contexts?()

        IDInfoTable.create_table?()

        db.setup_infrastructure_extras()
      end

      def migrate_specfic_models(direction, model_names)
        migrate_all_models(direction, model_names)
      end

      def migrate_all_models(direction, filter = nil)
        # order is important
        user_models = ret_user_models()
        user_models.each do |model|
          model.create_column_defs_common_fields?(direction, user_model: true)
        end

        concrete_models = ret_concrete_models(filter)
        (concrete_models - user_models).each do |model|
          model.create_column_defs_common_fields?(direction)
        end
        concrete_models.each { |model| model.apply_migration_defs(direction) }
        concrete_models.each(&:set_global_db_rel_info)
        concrete_models.each(&:preprocess!)

        concrete_models.each do |model|
          model.create_column_defs_specific_fields?(direction)
        end
        concrete_models.each { |model| model.create_associations?(direction) }
      end

      def initialize_all_models(db)
        set_db_for_all_models(db)
        concrete_models = ret_concrete_models()
        concrete_models.each { |model| model.apply_migration_defs(:up) }
        concrete_models.each(&:set_global_db_rel_info)
        DB_REL_DEF[:datacenter] = DB_REL_DEF[:target] #TODO: remove temp datacenter->target
        concrete_models.each(&:preprocess!)
        # returns model_names
        concrete_models.map { |klass| ret_relation_type(klass) }
      end
    #######

      def set_global_db_rel_info
        DB_REL_DEF[@relation_type] = @db_rel
      end

      def ret_concrete_models(filter = nil)
        # ret = models.reject {|m|m.top? or not m.superclass == Model}
        # count BaseModule as a Model superclass because it is used as a superclass for component_module, test_module, etc.
        ret = models.reject { |m| m.top? or not m.superclass == Model and m.superclass != BaseModule }
        if filter
          model_classes = filter.map { |model_name| Model.model_class(model_name) }
          ret.reject! { |m| !model_classes.include?(m) }
        end
        ret
      end

      def ret_user_models
        [XYZ::User, XYZ::UserGroup, XYZ::UserGroupRelation]
      end

      def create_column_defs_common_fields?(direction, opts = {})
        create_table_common_fields?(@db_rel, opts) if direction == :up
      end

      def apply_migration_defs(direction)
        case direction
          when :up
            up()
            has_ancestor_field()
          when :down
            down()
        end
      end

      def create_column_defs_specific_fields?(direction)
        case direction
          when :up
            create_table_specific_fields?(@db_rel)
          when :down
          # TODO: not implemented yet
        end
      end

      def create_associations?(direction)
        case direction
          when :up
            @db.create_table_associations?(@db_rel)
          when :down
          # TODO: not implemented yet
        end
      end

      def set_db(db)
        @db = db
      end

      ###### for shortcuts in virtual column
      class VCShortcut
      end
      class VCShortcutID < VCShortcut
        def initialize(parent_model_name)
          @parent_model_name = parent_model_name
        end

        def val(model_name)
          DB.parent_field(@parent_model_name, model_name)
        end
      end

      class VCShortcutParent < VCShortcut
        def initialize(model_name, parent_model_name)
          @parent_model_name = parent_model_name
          @model_name = model_name
        end

        def val
          "#{@model_name}__#{DB.parent_field(@parent_model_name, @model_name)}".to_sym
        end
      end

      def id(parent_model_name)
        VCShortcutID.new(parent_model_name)
      end

      def p(model_name, parent_model_name)
        VCShortcutParent.new(model_name, parent_model_name)
      end

      def q(model_name, field)
        "#{model_name}__#{field}".to_sym
      end

      # TODO: this would be good place to do parsing to check for errors in vc defs
      def preprocess!
        (@db_rel[:virtual_columns] || {}).each_value do |vc|
          remote_deps = vc[:remote_dependencies]
          next unless remote_deps
          remote_deps = remote_deps.values.first if remote_deps.is_a?(Hash)
          remote_deps.each do |join_info|
            (join_info[:cols] || []).each_with_index do |col, i|
              next unless col.is_a?(VCShortcutID)
              join_info[:cols][i] = col.val(join_info[:model_name])
            end
            # TODO: only applying translation  on {k => v} to v side, should apply to k side too
            (join_info[:join_cond] || {}).each do |k, v|
              next unless v.is_a?(VCShortcutParent)
              join_info[:join_cond][k] = v.val()
            end
            preprocess_add_needed_join_info_cols!(join_info)
            preprocess_substitutue_join_info_vcols!(join_info)
          end
        end
        self
      end

    private

      def preprocess_add_needed_join_info_cols!(join_info)
        return unless join_info[:cols]
        (join_info[:join_cond] || {}).each_key do |k|
          local_col = k
          if k.to_s =~ /(^.+)__(.+$)/
            next unless Regexp.last_match(1).to_sym = join_info[:model_name]
            local_col = Regexp.last_match(2).to_sym
          end
          join_info[:cols] << local_col unless join_info[:cols].include?(local_col)
        end
      end

      def preprocess_substitutue_join_info_vcols!(join_info)
        return unless join_info[:cols]
        new_field_set = Model::FieldSet.new(join_info[:model_name], join_info[:cols]).with_replaced_local_columns?()
        join_info[:cols] = new_field_set.cols if new_field_set
      end

      # TODO: drive off of  COMMON_REL_COLUMNS
      def create_table_common_fields?(db_rel, opts = {})
        create_schema_for_db_rel?(db_rel)
        seq_ref = @db.ret_sequence_ref(TOP_LOCAL_ID_SEQ)
        @db.create_table?(db_rel) do
          # TODO: do we want user models indexed by context
          foreign_key CONTEXT_ID, CONTEXT_TABLE.schema_table_symbol, FK_CASCADE_OPT.merge({ null: false, type: ID_TYPES[:context_id] })
          primary_key :id, type: ID_TYPES[:id], null: false
          column :local_id, ID_TYPES[:local_id], default: Sequel::LiteralString.new(seq_ref), null: false
          String :ref
          Integer :ref_num
          String :description
          String :display_name
          Timestamp :created_at
          Timestamp :updated_at
          unless opts[:user_model]
            foreign_key :owner_id, USER_TABLE.schema_table_symbol, FK_CASCADE_OPT.merge({ type: ID_TYPES[:id] })
            foreign_key :group_id, USER_GROUP_TABLE.schema_table_symbol, FK_CASCADE_OPT.merge({ type: ID_TYPES[:id] })
          end
        end

        @db.create_table_common_extras?(db_rel)
      end

      # Depedency; must be called after create_table_common_fields?
      def create_table_specific_fields?(db_rel)
        cols = db_rel[:columns]
        return nil if cols.nil?
        cols.each { |col, col_info|
          if fk_rel = col_info[:foreign_key_rel_type]
            other_col_info = col_info.reject { |k, _v| k == :foreign_key_rel_type }
            fail Error.new("#{fk_rel} is in foreign key DSL and does not exist") if DB_REL_DEF[fk_rel].nil?
            @db.add_foreign_key? db_rel, col, DB_REL_DEF[fk_rel], other_col_info
          else
            other_col_info = col_info.reject { |k, _v| k == :type }

            type = col_info[:type] == :json ? :text : col_info[:type]
            # explicitly setting size to nil to handle dbrebuild which removes size restriction
            if !other_col_info.key?(:size) and [:varchar].include?(type)
              other_col_info = other_col_info.merge(size: nil)
            end

            @db.add_column? db_rel, col, type, other_col_info
          end
        }
        nil
      end

      def create_schema_for_db_rel?(db_rel)
        schema = db_rel[:schema]
        return nil if schema.nil?
        return nil if schema == :public
        @db.create_schema?(schema)
      end

     def convert_to_db_rel_form(*arg)
        case arg.size
          when 1
            DBRel[schema: :public, table: arg[0]]
          when 2
            DBRel[schema: arg[0], table: arg[1]]
        end
      end

      def models
        classes = []
        ObjectSpace.each_object(Module) do |m|
          classes << m if m.ancestors.include? self and m != self
        end

        # count BaseModule as a Model superclass because it is used as a superclass for component_module, test_module, etc.
        ObjectSpace.each_object(BaseModule) do |m|
          classes << m if m.ancestors.include? self and m != self
        end

        # remove BaseModule from models list because it's only used as a superclass for other module types
        classes.reject! { |c| c == BaseModule }
        classes
      end
  end
end
