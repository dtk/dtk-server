module XYZ
  class Postgres < DB
    def initialize(db_params)
      super()
      @db = Sequel.postgres(db_params[:name], :user => db_params[:user],  :host => db_params[:hostname], :password => db_params[:pass])
    end


    def ret_array_dataset(rows)
      ds = @db.dataset()
      sql = String.new
      cols = rows.first.keys()
      cols.each do |col|
        sql << "," unless sql.empty?
        sql << " unnest(ARRAY[#{rows.map{|row|ds.literal(row[col])}.join(",")}]) as #{col}"
      end
      ds.select(::Sequel::LiteralString.new(sql))
    end

    def update_returning_sql(ds,update_set_clause,returning_list)
      sql = ds.update_sql(update_set_clause)
      sql << " RETURNING " + returning_list.map do |x| 
        if x.kind_of?(Hash) 
          "#{@db.literal(x.keys.first)} AS #{x.values.first}"
        else
          @db.literal(x)
        end
      end.join(",")
      sql
    end

    def setup_infrastructure_extras()
      create_language?(:plpgsql) # needed for triggers
      create_function_zzz_ret_id?()
      create_element_update_trigger?()
      create_sequence?(TOP_LOCAL_ID_SEQ,ID_TYPES[:local_id]) 
      
      # custom functions
      create_custom_function__append_to_array_value?()
    end

    def create_table_common_extras?(db_rel)
      create_table_common_fields_trigger?(db_rel) 
    end

    def ret_sequence_ref(seq_name)
      seq_qualified_name = fully_qualified_fn_name(seq_name)
      "nextval('#{seq_qualified_name}'::regclass)"
    end

  protected     

    def create_function_zzz_ret_id?() 
      o =  ID_TYPES[:id] # fn output
      raise Error::NotImplemented.new("create_function_zzz_ret_id?") if !(o == :bigint and ID_TYPES[:context_id] == :integer and ID_TYPES[:local_id] == :integer)
      create_function?({:schema => :top,:fn => :zzz_ret_id},
        "SELECT CASE WHEN $1 = 1 THEN $2::bigint ELSE (2147483648::bigint * ($1 -1)::bigint) + $2::bigint end",
        :returns => :bigint, :behavior => :IMMUTABLE, :args => [{:_context_id => :integer}, {:_local_id => :integer}])
    end

    def create_element_update_trigger?()
      uri_rel = fully_qualified_rel_name(ID_INFO_TABLE)
      uri_id = ID_INFO_TABLE[:id].to_s
      uri_local_id = ID_INFO_TABLE[:local_id].to_s
      c = CONTEXT_ID.to_s
      parent_id = ID_INFO_TABLE[:parent_id].to_s

      create_function? ELEMENT_UPDATE_TRIGGER,
         "BEGIN
            IF TG_OP = 'INSERT' THEN 
              SELECT INTO new.id top.zzz_ret_id(NEW.#{c},NEW.local_id);
              INSERT INTO #{uri_rel} (#{uri_id},#{uri_local_id},#{c},relation_name,ref,ref_num) 
              VALUES (NEW.id,NEW.local_id,NEW.#{c},TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,NEW.ref,NEW.ref_num);
              RETURN NEW;
            ELSIF TG_OP = 'UPDATE' THEN 
	      --TBD: not implemented
            RETURN NEW;
            END IF;
            -- else TG_OP = DELETE
            DELETE FROM #{uri_rel}
            WHERE #{uri_id} = OLD.id OR #{parent_id} = OLD.id;
            RETURN OLD;
         END",  
	 :returns => "trigger", :language => "plpgsql"
    end

    def create_table_common_fields_trigger?(db_rel)
      create_trigger?(db_rel,ELEMENT_UPDATE_TRIGGER[:fn],ELEMENT_UPDATE_TRIGGER,:each_row => true)
    end

    def create_trigger(db_rel,trigger_name,db_fn,opts={})
      trigger_fn = fully_qualified_fn_name(db_fn)
      @db.create_trigger(db_rel.schema_table_symbol,trigger_name,trigger_fn,opts)
      nil
    end

    def trigger_exists?(db_rel,trigger_name)
      x = ret_schema_and_table(db_rel)
      query = "SELECT count(*) FROM pg_trigger t, pg_class r, pg_namespace s
         WHERE t.tgrelid = r.oid AND r.relnamespace = s.oid AND
	       t.tgname = '#{trigger_name}' AND r.relname = '#{x[:table].to_s}' AND s.nspname = '#{x[:schema].to_s}'"
      db_fetch(query) {|r| return r[:count] == 1 ? true : nil}
    end

    def create_trigger?(db_rel,trigger_name,trigger_fn,opts={})
      create_trigger(db_rel,trigger_name,trigger_fn,opts) if !trigger_exists?(db_rel,trigger_name)
      nil
    end

    def create_schema(schema_name)
      db_run "CREATE SCHEMA #{schema_name.to_s}"
      nil
    end

    def schema_exists?(schema_name)
      @db.from(:pg_namespace).where(:nspname => schema_name.to_s).empty? ?  nil : true
    end

    def create_language(language_name)
      @db.create_language(language_name)
      nil
    end
 
    def language_exists?(language_name)
      @db.from(:pg_language).where(:lanname => language_name.to_s).empty? ?  nil : true
    end

    def create_language?(language_name)
      create_language(language_name) if !language_exists?(language_name)
      nil
    end

    def function_exists?(db_fn)
      x = ret_schema_and_fn(db_fn)
      query = "SELECT count(*) FROM pg_proc, pg_namespace
           WHERE proname = '#{x[:fn].to_s}' AND nspname = '#{x[:schema].to_s}' AND
                  pg_proc.pronamespace = pg_namespace.oid"
       db_fetch(query) {|r| return r[:count] == 1 ? true : nil}
    end

    def create_function(db_fn,definition,opts={})
      @db.create_function(fully_qualified_fn_name(db_fn),definition,opts)
      nil
    end 		   

    def create_function?(db_fn,definition,opts={})
      create_function(db_fn,definition,opts) if !function_exists?(db_fn)
      nil
    end

    def column_exists?(db_rel,column)
      r = ret_schema_and_table(db_rel)
      query = "SELECT count(*)
               FROM  pg_class rel, pg_namespace s, pg_attribute col
               WHERE rel.relnamespace =  s.oid AND 
                     s.nspname = '#{r[:schema].to_s}' AND rel.relname = '#{r[:table].to_s}' AND
                     col.attrelid = rel.oid AND
                     col.attname = '#{column.to_s}'"
      db_fetch(query) {|r| return r[:count] == 1 ? true : nil}
    end

    def foreign_key_exists?(db_rel,foreign_key_field,db_rel_pointed_to)
      r = ret_schema_and_table(db_rel)
      p = ret_schema_and_table(db_rel_pointed_to)
      query = "SELECT count(*)
               FROM pg_constraint fk, pg_class rel, pg_class parent_rel, pg_attribute f, 
                    pg_namespace rel_s,pg_namespace parent_rel_s
               WHERE fk.contype = 'f' AND fk.conrelid = rel.oid AND
                     fk.confrelid = parent_rel.oid AND
                     fk.conkey[1] = f.attnum AND f.attrelid = rel.oid AND
                     rel.relnamespace =  rel_s.oid AND parent_rel.relnamespace = parent_rel_s.oid AND
                     rel_s.nspname = '#{r[:schema].to_s}' AND rel.relname = '#{r[:table].to_s}' AND
		     parent_rel_s.nspname = '#{p[:schema].to_s}' AND parent_rel.relname = '#{p[:table].to_s}' AND
		     f.attname = '#{foreign_key_field.to_s}'"
      db_fetch(query) {|r| return r[:count] == 1 ? true : nil}
    end

    def create_sequence(seq_name,type)
      max_value = 
        case type
          when :integer
            9223372036854775807 
          when :bigint
            9223372036854775807
      	end

      raise Error::NotImplemented.new("sequence for type #{type.to_s}") if max_value.nil?

      seq_qualified_name = fully_qualified_fn_name(seq_name)
      db_run "CREATE SEQUENCE #{seq_qualified_name}
               INCREMENT 1
  	       MINVALUE 1
  	       MAXVALUE #{max_value.to_s}
  	       START 1
  	       CACHE 1"
      nil
    end

    def sequence_exists?(seq_name)
      r = ret_schema_and_fn(seq_name)
      query = "SELECT count(*)
               FROM  pg_class rel, pg_namespace s
               WHERE rel.relnamespace =  s.oid AND rel.relkind = 'S' AND
                     s.nspname = '#{r[:schema].to_s}' AND rel.relname = '#{r[:fn].to_s}'"
     db_fetch(query) {|r| return r[:count] == 1 ? true : nil}
    end

    def create_sequence?(seq_name,type)
      create_sequence(seq_name,type) unless sequence_exists?(seq_name)
    end

    def fully_qualified_fn_name(fn)
      fn.kind_of?(Hash) ? (fn[:schema].to_s +  "." + fn[:fn].to_s) : fn
    end

  public
    
    def fully_qualified_rel_name(rel)
      rel.kind_of?(Hash) ? (rel[:schema].to_s +  "." + rel[:table].to_s) : rel
    end

  private
    def execute_function_aux(fn_name,*args)
      @db.get("#{FUNCTION_SCHEMA}.#{fn_name}".to_sym.sql_function(*args))
    end

    def ret_schema_and_table(rel)
      rel.kind_of?(Hash) ? rel : {:schema => :public, :table => rel}
    end
    def ret_schema_and_fn(fn)
      fn.kind_of?(Hash) ? fn : {:schema => :public, :fn => :fn}
    end
#####custom functions
    def create_custom_function__append_to_array_value?()
      fn_args =
        [
         {:schema => FUNCTION_SCHEMA,:fn => :append_to_array_value},
         "DECLARE
    arr varchar[];
    ret integer;
    new_vals varchar;
    max_index integer := 0;
   BEGIN
   SELECT  regexp_split_to_array(regexp_replace(value_derived,'.$',''),'},{')
     INTO arr
     FROM attribute.attribute WHERE id = _id and c = _c;
   IF arr IS NULL THEN
     ret := 0;
     new_vals := _vals_to_app;
   ELSE
    ret := array_upper(arr,1);
    new_vals := array_to_string(arr,'},{') || regexp_replace(_vals_to_app,'^.',',');
  END IF;

   UPDATE attribute.attribute SET value_derived = new_vals
    WHERE id = _id and c = _c;
   RETURN ret;
  END",
         {
           :returns => :integer, 
           :language => "plpgsql",
           :behavior => :VOLATILE, 
           :args => [{:_c => :integer}, {:_id => ID_TYPES[:id]},{:_vals_to_app => :varchar}]
         }
        ]
      create_function?(*fn_args)
    end
  end
end
