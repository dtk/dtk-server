require 'sequel'
require 'singleton'
require 'pp'
class DTKMigration
  require File.expand_path('../app_migration', File.dirname(__FILE__))
  include DTK
  def initialize()
    c = 2
    @user_mh = ModelHandle.new(c,:user)
    user_superuser = User.create_user_in_groups?(ModelHandle.new(c,:user),"superuser")
    CurrentSession.new.set_user_object(user_superuser)
  end
  
  def db_rebuild(*model_names)
    Model.db_rebuild(DBinstance,model_names,Opts.new(:raise_error => true))
  end
  
  def get_objs(model_name,sp_hash)
    Model.get_objs(mh(model_name),sp_hash, :convert => true)
  end
  
  def create_objs(model_name,parent_model_name,rows,old_model_name=nil)
    ndx_user_date_ref_info = (old_model_name ? get_ndx_user_date_ref_info(old_model_name,rows.map{|r|r[:old_id]}.compact) : {})
    create_columns = rows.first.keys - [:old_id] #taking first row because they all have same columns
    create_rows = rows.map do |r|
      el = nil
      if ndx = r[:old_id]
        if user_date_ref_info = ndx_user_date_ref_info[ndx]
          el = Aux.hash_subset(r,create_columns).merge(user_date_ref_info)
        end
      end
      el || r
    end
    mh = mh(model_name).merge(:parent_model_name => parent_model_name)
    Model.create_from_rows_for_migrate(mh,create_rows)
  end

  private
  def mh(model_name)
    @user_mh.createMH(model_name)
  end

  def get_ndx_user_date_ref_info(model_name,ids)
    ret = Hash.new
    return ret if ids.empty?
    sp_hash = {
      :cols => [:id]+UserDateRefCols,
      :filter => [:oneof,:id,ids]
    }
    get_objs(model_name,sp_hash).inject(Hash.new){|h,r|h.merge(r[:id] => Aux.hash_subset(r,UserDateRefCols))}
  end
  UserDateRefCols = [:ref,:owner_id,:group_id,:created_at,:updated_at]
end
