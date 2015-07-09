require File.expand_path('chef_server_connection', File.dirname(__FILE__))
# TBD: some of these fns refer to model object clouns; not sure if shoudl move to be on model objects,
# but then issue would be that the pasring fns refer to the form of input source
module XYZ
  class ChefProcessor
    class Metadata
      def get(_cookbooks_uris, &_block)
        fail Error::NotImplemented.new("get meta data for #{self.class}")
      end

      protected

      def format_metadata(metadata)
   return nil if metadata.nil?
   return nil if metadata['name'].nil?
   attributes = {}
   attributes_defs = {}
   unless metadata['attributes'].nil?
     metadata['attributes'].each {|recipe_ref, values|
       #to strip of recipe name prefix if that is the case
       ref_imploded = recipe_ref.split('/')
       ref = ((ref_imploded[0] == metadata['name'] and ref_imploded.size > 1) ?
         ref_imploded[1..ref_imploded.size - 1].join('/') : recipe_ref).to_sym
       data_type = case values['type']
         when 'hash', 'array'
           'json'
         else
           values['type']
       end
       attributes[ref] = {
         display_name: values['display_name'],
         value_asserted: values['default'],
         constraints: values['constraints']
             }
       attributes_defs[ref] = {
         external_attr_ref: recipe_ref.to_s,
         port_type: values['port_type'],
         semantic_type: values['semantic_type'] ? values['semantic_type'].to_json : nil,
         data_type: data_type,
         display_name: values['display_name'],
         description: values['description'],
         default: values['default'],
         constraints: values['constraints']
             }
     }
   end
         component_obj =
           { metadata['name'].to_sym =>
       { display_name: metadata['display_name'] ? metadata['display_name'] : metadata['name'],
         description: metadata['description'],
         attribute: attributes } }
         component_def_obj =
           { metadata['name'].to_sym =>
       { external_type: 'chef_recipe',
         external_cmp_ref: metadata['name'],
         attribute_def: attributes_defs,
         uri: nil } } #stub
         [component_obj, component_def_obj]
      end

    end

    class MetadataFromServer < Metadata
      include ChefServerConnection
      def get(chef_server_uri, &_block) #TBD: chef_server_uri is stub
        initialize_chef_connection(chef_server_uri)
  get_cookbook_list().each_key {|cookbook_name|
    component_object, implementation_object = get_cookbook_metadata(cookbook_name)
    yield cookbook_name, component_object, implementation_object, nil
    Log.info("loaded recipe #{cookbook_name}")
  }
  nil
      end

      def get_cookbook_list
        get_rest('cookbooks').to_hash
      end

      def get_cookbook_metadata(cookbook_name)
        r = get_rest("cookbooks/#{cookbook_name}")
  return nil if r.nil?
    format_metadata(r['metadata'])
      end
    end

    class MetadataFromFile < Metadata
      def get(local_dir, &_block)
        #TBD: these should probably be done in task preconidtion that is part of synchronous a prior arguement checking
        fail Error.new("#{local_dir} does not exist") unless  File.exist?(local_dir)
        fail Error.new("#{local_dir} is not a directory") unless  File.directory?(local_dir)
  Dir.foreach(local_dir) do |cookbook_name|
    next if !File.directory?(local_dir + '/' + cookbook_name) or cookbook_name =~ %r{^[.]}
    component_obj = component_def_obj = nil
    begin
     component_obj, component_def_obj = get_cookbook_metadata(cookbook_name, local_dir)
     rescue Exception => err
      #TBD: need to trap to assert which recipe this is associated with; want error that is json parsing error
      yield cookbook_name, nil, nil, err
      next
    end
    if component_obj or component_def_obj
      yield cookbook_name, component_obj, component_def_obj, nil
            Log.info("loaded recipe #{cookbook_name}")
    else
      yield cookbook_name, nil, nil, Error.new("no meta file for recipe #{cookbook_name} found")
          end
        end
  nil
      end

      private

      def get_cookbook_metadata(cookbook_name, local_dir)
  metadata_file = "#{local_dir}/#{cookbook_name}/metadata.json"
  return nil unless File.exist?(metadata_file)
  ret = nil
  File.open(metadata_file) { |f| ret = JSON.parse(f.read) }
  format_metadata(ret)
      end
    end
  end
end
