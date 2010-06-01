module XYZ
  module InputIntoModelClassMixins

    def assoc_key(key)
      "*" + key.to_s
    end
    def is_assoc_key?(key)
      key.kind_of?(String) and key[0,1] == "*"
    end
    def removed_assoc_mark(key)
      is_assoc_key?(key) ? key[1,key.size-1] : key
    end 

    #hash_with_assocs has form {obj1_type => ..,obj2_type => ...}
    def input_into_model(container_id_handle,hash_with_assocs)
      c = container_id_handle[:c]
      refs = Hash.new
      remove_refs_and_return_refs!(hash_with_assocs,refs)

      prefixes = []
      hash_with_assocs.each do |relation_type,obj|
	factory_id_handle = get_factory_id_handle(container_id_handle,relation_type.to_sym)
        new_prefixes = create_from_hash(factory_id_handle,obj)
        prefixes.push(*new_prefixes).uniq!
      end
      update_with_id_values(refs,c,prefixes)
    end
   private
    def remove_refs_and_return_refs!(obj,refs,path="")
      obj.each_pair do |k,v|
        if v.kind_of?(Hash) 
	  remove_refs_and_return_refs!(v,refs,path + "/" + k.to_s)	    
        elsif v.kind_of?(Array)
	  next
        elsif is_assoc_key?(k)
	  refs[path] ||= {}
	  refs[path][removed_assoc_mark(k)] = v 
	  obj.delete(k)
        end 
      end
    end  
    def update_with_id_values(refs,c,prefixes)
      refs.each_pair do |fk_rel_uri_x,info|
        fk_rel_uri = ret_rebased_uri(fk_rel_uri_x ,prefixes)
	fk_rel_id_handle = IDHandle[:c => c, :uri => fk_rel_uri]
	info.each_pair do |col,ref_uri_x|
          ref_uri = ret_rebased_uri(ref_uri_x,prefixes)
	  ref_id_info = get_row_from_id_handle(IDHandle[:c => c, :uri => ref_uri])
	  raise Error.new("In import cannot find object with uri #{ref_uri}") unless ref_id_info[:id]
	  update_instance(fk_rel_id_handle,{col.to_sym =>  ref_id_info[:id]})	  
        end
      end
    end

    def ret_rebased_uri(uri_x,prefixes)
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
        raise Error 
      end
      # find prefix that matches and rebase
      #TBD: don't think this is exactly right
      prefix_matches = []
      prefixes.each{|prefix|
	prefix =~ %r{^.+/(.+?)/(.+?$)}
	raise Error unless prefix_ref = $2
        prefix_rt = $1
	if relation_type_string == prefix_rt 
	  if ref == prefix_ref
	    return prefix + stripped_uri 
          elsif refs_have_common_base(ref,prefix_ref) 
           prefix_matches << prefix
          end
        end
      }
      return prefix_matches[0] + stripped_uri if prefix_matches.size == 1
      raise Error.new("not handling case where not exact, but or more prfix matches") if prefix_matches.size  > 1
      raise Error 
    end

    def refs_have_common_base(x,y)
      x =~ Regexp.new("^" + y + "-[0-9]+$") or y =~ Regexp.new("^" + x + "-[0-9]+$")
    end
  end
end

