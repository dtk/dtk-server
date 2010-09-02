module XYZ
  module CreateObjectsClassMixins
    #TBD: may remove create_simple_instance?
    def create_simple_instance?(new_uri,c,opts={})
      return new_uri if exists? IDHandle[:uri => new_uri, :c => c]
      ref,factory_uri = RestURI.parse_instance_uri(new_uri)
      @db.create_from_hash(IDHandle[:c => c, :uri => factory_uri],{ref => {}}).first
    end
=begin deprecate create file and use update
    def create_from_hash(id_handle,hash,clone_helper=nil,opts={})
      @db.create_from_hash(id_handle,hash,clone_helper,opts)
    end
=end
    def create_from_hash(id_handle,hash,clone_helper=nil,opts={})
      #TODO: factor back in clone_helper
      @db.update_from_hash_assignments(id_handle,hash,opts)
    end
  end
end
