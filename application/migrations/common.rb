require 'sequel'
require 'singleton'
require 'pp'
class DTKMigration
  def self.dtk_model_context(&block)
    DTKModelHelper.instance.instance_eval &block
  end

  class DTKModelHelper
    include Singleton

    def dtk_db_rebuild(*model_names)
      Model.db_rebuild(model_names,Opts.new(:raise_error => true, :db => dtk_db()))
    end
  
    def dtk_get_objs(model_name,sp_hash)
      Model.get_objs(mh(model_name),sp_hash,:keep_ref_cols => true)
    end
    
    def dtk_create_objs(model_name,parent_model_name,rows,old_model_name=nil)
      ndx_user_date_ref_info = Hash.new 
      if old_model_name 
        ids = rows.map{|r|r[:old_id]}.compact
        ndx_user_date_ref_info = UserDateRefCols.get(self,old_model_name,ids).inject(Hash.new){|h,r|h.merge(r[:id] => r)}
      end

      create_columns = rows.first.keys - [:old_id] #taking first row because they all have same columns
      create_rows = rows.map do |r|
        el = nil
        if ndx = r[:old_id]
          if user_date_ref_info = ndx_user_date_ref_info[ndx]
            #info in create_columns can over write info in user_date_ref_info
          el = user_date_ref_info.merge(Aux.hash_subset(r,create_columns))
          end
        end
        el || r
      end
      mh = mh(model_name).merge(:parent_model_name => parent_model_name)
      Model.create_from_rows_for_migrate(mh,create_rows)
    end
    
   private
    def dtk_db()
      #TODO: this gets set now in ../app_migratin; can clean this up
      DBinstance
    end

    def initialize()
      require File.expand_path('../app_migration', File.dirname(__FILE__))
      self.class.class_eval{include DTK}
      c = 2
      @user_mh = ModelHandle.new(c,:user)
      user_superuser = User.create_user_in_groups?(ModelHandle.new(c,:user),"superuser")
      CurrentSession.new.set_user_object(user_superuser)
    end

    def mh(model_name)
      @user_mh.createMH(model_name)
    end
    
    module UserDateRefCols
      def self.get(parent,model_name,ids)
        ret = Hash.new
        return ret if ids.empty?
        sp_hash = {
          :cols => [:id]+Cols,
          :filter => [:oneof,:id,ids]
        }
        parent.dtk_get_objs(model_name,sp_hash).map do |raw_row|
          raw_row.inject(Hash.new){|h,(col,val)|h.merge(col => val|| null_val(col))}
        end
      end

      def self.null_val(col)
        case col
          when :ref_num then ::DTK::SQL::ColRef.cast(nil,:integer)
        end
      end

      # Cols = [:ref,:ref_num,:owner_id,:group_id,:created_at,:updated_at]
      Cols = [:ref,:ref_num,:owner_id,:group_id]
    end
      
  end
end
