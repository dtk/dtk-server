module XYZ
  #class mixin
  module ImportObject
    #not idempotent
    def import_objects_from_file(target_id_handle,json_file)
      c = target_id_handle[:c]
      raise Error.new("Target given (#{target_id_handle}) does not exist") unless exists? target_id_handle 
      raise Error.new("file given #{json_file} does not exist") unless File.exists?(json_file)
      hash_content = nil
      File.open(json_file){|f| 
        begin
	  json = f.read
         rescue Exception => err
          raise Error.new("error reading file (#{json_file}): #{err}")
         end
         begin
           hash_content = JSON.parse(json)
          rescue Exception
           raise Error.new("file (#{json_file} has json parsing error")
         end
      }

      refs={}
      remove_refs_and_return_refs!(hash_content,refs)

      prefixes = []
      #hash_content has form {obj1_type => ..,obj2_type => ...}
      hash_content.each{|relation_type,obj|
	factory_id_handle = get_factory_id_handle(target_id_handle,relation_type.to_sym)
        new_prefixes = create_from_hash(factory_id_handle,obj)
        prefixes.push(*new_prefixes).uniq!
      }
      update_with_id_values(refs,c,prefixes)
    end
   private
    def remove_refs_and_return_refs!(obj,refs,path="")
      obj.each_pair{|k,v|
        if v.kind_of?(Hash) 
	  remove_refs_and_return_refs!(v,refs,path + "/" + k)	    
        elsif v.kind_of?(Array)
	  next
        elsif k[0,1] == "*" 
	  refs[path] ||= {}
	  refs[path][k[1,v.size-1]] = v 
	  obj.delete(k)
        end 
      }
    end  
    def update_with_id_values(refs,c,prefixes)
      refs.each_pair{|fk_rel_uri_x,info|
        fk_rel_uri = ret_rebased_uri(fk_rel_uri_x ,prefixes)
	fk_rel_id_handle = IDHandle[:c => c, :uri => fk_rel_uri]
	info.each_pair{|col,ref_uri_x|
          ref_uri = ret_rebased_uri(ref_uri_x,prefixes)
	  ref_id_info = get_row_from_id_handle(IDHandle[:c => c, :uri => ref_uri])
	  raise Error.new("In import cannot find object with uri #{ref_uri}") unless ref_id_info[:id]
	  update_instance(fk_rel_id_handle,{col.to_sym =>  ref_id_info[:id]})	  
        }
      }
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

