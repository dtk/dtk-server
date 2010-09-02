module XYZ
  module CreateObjectsClassMixins
    #TBD: may remove create_simple_instance?
    def create_simple_instance?(new_uri,c,opts={})
      return new_uri if exists? IDHandle[:uri => new_uri, :c => c]
      ref,factory_uri = RestURI.parse_instance_uri(new_uri)
      @db.create_from_hash(IDHandle[:c => c, :uri => factory_uri],{ref => {}}).first
    end
    def create_from_hash(id_handle,hash,clone_helper=nil,opts={})
      @db.create_from_hash(id_handle,hash,clone_helper,opts)
    end
  end
end
