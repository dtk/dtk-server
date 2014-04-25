module XYZ
  module InputIntoModelClassMixins
    include CommonInputImport
    def input_into_model(container_id_handle,hash_with_assocs,opts={})
      fks = Hash.new
      hash_assigns = remove_fks_and_return_fks!(hash_with_assocs,fks,opts)
      prefixes = update_from_hash_assignments(container_id_handle,hash_assigns)
      ret_global_fks = nil
      unless fks.empty?
        container_id_info = IDInfoTable.get_row_from_id_handle(container_id_handle)
        ret_global_fks = update_with_id_values(fks,container_id_handle[:c],prefixes,container_id_info[:uri],opts)
      end
      if opts[:preserve_input_hash]
        insert_fks_back_in_hash!(hash_with_assocs,fks)
      end

      if opts[:return_info]
        return ret_global_fks, prefixes
      else
        return ret_global_fks
      end
    end

    #TODO: using mixed forms (ForeignKeyAttr class and "*" form) now to avoid having to convert "*" form when doing an import
    def mark_as_foreign_key(attr,opts={})
      ForeignKeyAttr.new(attr,opts)
    end
   private
    def is_foreign_key_attr?(attr)
      attr.kind_of?(ForeignKeyAttr) or (attr.kind_of?(String) and attr[0,1] == "*")
    end
    def foreign_key_attr_form(attr)
      return attr if attr.kind_of?(ForeignKeyAttr)
      ForeignKeyAttr.new(attr[0,1] == "*" ? attr[1,attr.size-1] : attr)
    end 

    class ForeignKeyAttr 
      attr_reader :create_ref_object, :attribute
      def initialize(attribute,opts={})
        @attribute=attribute
        @create_ref_object=opts[:create_ref_object]
      end      
      def to_s()
        @attribute
      end
      def to_sym()
        to_s().to_sym()
      end
    end

    def remove_fks_and_return_fks!(obj,fks,opts={},path="")
      obj.each_pair do |k,v|
        if v.kind_of?(Hash) 
	  remove_fks_and_return_fks!(v,fks,opts,path + "/" + k.to_s)	    
        elsif v.kind_of?(Array)
	  next
        elsif is_foreign_key_attr?(k)
	  fks[path] ||= Hash.new
	  fks[path][foreign_key_attr_form(k)] = modify_uri_with_user_name(v,opts[:username]) 
	  obj.delete(k)
        end 
      end
      obj
    end  

    def insert_fks_back_in_hash!(hash,fks)
      fks.each do |string_path,fk_info|
        path = string_path.split("/")
        path.shift if path.first.empty?
        assign = fk_info.inject(Hash.new) do |h,(fk_attr,v)|
          h.merge("*#{fk_attr.attribute}" => v)
        end
        insert_assign_at_path!(hash,path,assign)
      end
    end
    def insert_assign_at_path!(hash,path,assign)
      first = path.shift
      if hash.has_key?(first.to_s)
        key = first.to_s
      elsif hash.has_key?(first.to_sym)
        key = first.to_sym
      else
        raise Error.new("Unexpecetd path element (#{first})")
      end
      if path.empty?
        if hash[key].nil?
          hash[key] = assign
        else
          hash[key].merge!(assign)
        end
      else
        insert_assign_at_path!(hash[key],path,assign)
      end
    end

    def update_with_id_values(fks,c,prefixes,container_uri,opts={})
      ret_global_fks = nil
      fks.each_pair do |fk_rel_uri_x,info|
        fk_rel_uri = ret_rebased_uri(fk_rel_uri_x ,prefixes,container_uri)
	fk_rel_id_handle = IDHandle[:c => c, :uri => fk_rel_uri]
	info.each_pair do |col,ref_uri_x|
          ref_uri = ret_rebased_uri(ref_uri_x,prefixes,container_uri)
	  ref_id_info = get_row_from_id_handle(IDHandle[:c => c, :uri => ref_uri])
          unless ref_id_info and ref_id_info[:id]
            if col.create_ref_object
              #TODO: check whether should also populate ds_key; may not be needed because
              #of relation between ds_key and relative distinguished name
              idh = IDHandle[:c => c, :uri => ref_uri]
              create_simple_instance?(idh,:set_display_name => true)
	      ref_id_info = get_row_from_id_handle(idh)
            else
              unless opts[:ret_global_fks]
                Log.error("In import_into_model cannot find object with uri #{ref_uri}") 
              else
                ret_global_fks ||= Hash.new
                #purposely using fk_rel_uri (rebaselined) but ref_uri_x (raw)
                ret_global_fks[fk_rel_uri] ||= Hash.new
                ret_global_fks[fk_rel_uri][col] = ref_uri_x
              end
              next
            end
          end
	  update_instance(fk_rel_id_handle,{col.to_sym =>  ref_id_info[:id]})	  
        end
      end
      ret_global_fks
    end
   
    def process_global_keys(global_fks,c)
      global_fks.each_pair do |fk_rel_uri,info|
	fk_rel_id_handle = IDHandle[:c => c, :uri => fk_rel_uri]
	info.each_pair do |col,ref_uri|
	  ref_id_info = get_row_from_id_handle(IDHandle[:c => c, :uri => ref_uri])
          unless ref_id_info and ref_id_info[:id]
            if col.create_ref_object
              #TODO: check whether should also populate ds_key; may not be needed because
              #of relation between ds_key and relative distinguished name
              idh = IDHandle[:c => c, :uri => ref_uri]
              create_simple_instance?(idh,:set_display_name => true)
	      ref_id_info = get_row_from_id_handle(idh)
            else
              Log.error("In process_global_keys cannot find object with uri #{ref_uri}") 
              next
            end
          end
	  update_instance(fk_rel_id_handle,{col.to_sym =>  ref_id_info[:id]})	  
        end
      end
    end

    def ret_rebased_uri(uri_x,prefixes,container_uri=nil)
      relation_type_string = stripped_uri = ref = nil
      if uri_x =~ %r{^/(.+?)/(.+?)(/.+$)} 
         relation_type_string = $1
         ref = $2
         stripped_uri = $3
      elsif  uri_x =~ %r{^/(.+)/(.+$)}
         relation_type_string = $1
         ref = $2
         stripped_uri = ""
      else
        #TODO: double check that everything that works heer is fine;being no op seems to work fine when uri_x is "" because it is referencing top level object like aproject
#TODO        raise Error 
      end
      # find prefix that matches and rebase
      #TODO: don't think this is exactly right
      prefix_matches = []
      prefixes.each{|prefix|
	prefix =~ %r{^.+/(.+?)/(.+?$)}
	raise Error unless prefix_ref = $2
        prefix_rt = $1
	if relation_type_string == prefix_rt 
	  if ref == prefix_ref
	    return prefix + stripped_uri 
          elsif fks_have_common_base(ref,prefix_ref) 
           prefix_matches << prefix
          end
        end
      }
      return prefix_matches[0] + stripped_uri if prefix_matches.size == 1
      raise Error.new("not handling case where not exact, but or more prfix matches") if prefix_matches.size  > 1
      #if container_uri is non null then uri_x can be wrt container_uri and this is assumed to be the case if reach here
      return container_uri + uri_x if container_uri
      raise Error 
    end

    def fks_have_common_base(x,y)
      x =~ Regexp.new("^" + y + "-[0-9]+$") or y =~ Regexp.new("^" + x + "-[0-9]+$")
    end
  end
end

