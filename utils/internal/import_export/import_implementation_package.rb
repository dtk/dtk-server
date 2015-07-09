# TODO: Marked for removal [Haris]
module XYZ
  module ImportImplementationPackage
    # this should be precded by fn that adds the component to R8::Config[:repo][:base_directory] location
    def self.add(library_idh, impl_name)
      version = '0.0.1' #TODO: stub
      r8meta_type = :yaml #TODO: stub

      # put component meta info in hash
      components_hash = get_r8meta_hash(impl_name, r8meta_type: r8meta_type)
      library = library_idh.create_object().update_object!(:ref)

      # put implement info in hash
      hash_content = { 'library' => { library[:ref] => { 'component' => components_hash } } }
      Model.add_implementations!(hash_content, version, library[:ref], R8::Config[:repo][:base_directory], impl_name)

      # create in db
      Model.input_hash_content_into_model(library_idh.create_top(), hash_content)
    end

    def self.add_or_update_component(parent_idh, component_name, opts = {})
      component_hash = get_r8meta_hash(component_name, opts)
      add_implementation_id!(component_hash, parent_idh, component_name)
      Model.input_into_model(parent_idh, { 'component' => { component_name => component_hash } })
    end

    private

    def self.get_r8meta_hash(cmp_or_impl_name, opts = {})
      r8meta_type = opts[:r8meta_type]
      r8meta_file = find_r8meta_file(cmp_or_impl_name, r8meta_type)
      ret = nil
      case r8meta_type
       when :yaml
        require 'yaml'
        ret = YAML.load_file(r8meta_file)
       else
        raise Error.new("Type #{r8meta_type} not supported")
      end
      ret
    end

    def self.find_r8meta_file(cmp_or_impl_name, r8meta_type)
      file_ext = TypeMapping[r8meta_type]
      raise Error.new('illegal type extension') unless file_ext
      repo = cmp_or_impl_name.gsub(/__.+$/, '')
      files = Dir.glob("#{R8::Config[:repo][:base_directory]}/#{repo}/r8meta.*.#{file_ext}")
      if files.empty?
        raise Error.new('Cannot find valid r8meta file')
      elsif files.size > 1
        raise Error.new('Multiple r8meta files found')
      end
      files.first
    end
    TypeMapping = {
      yaml: 'yml'
    }

    def self.add_implementation_id!(component_hash, parent_idh, component_name)
      impl_display_name = component_name.gsub(/__.+$/, '')
      sp_hash = {
        cols: [:id],
        filter: [:and, [:eq, :display_name, impl_display_name],
                 [:eq, DB.parent_field(parent_idh[:model_name], :implementation), parent_idh.get_id()]]
      }
      rows = Model.get_objs(parent_idh.createMH(:implementation), sp_hash)
      raise Error.new("Error in finding implementation for component #{component_name}") unless rows.size = 1
      component_hash.merge!(implementation_id: rows.first[:id])
    end

    def self.update_implementation_ids(library_idh, impl_name, component_refs)
      # TODO: can more effiiently implement witrh update_from_select
      library_id = library_idh.get_id()
      cmp_mh = library_idh.createMH(:component)
      sp_hash = {
        cols: [:id],
        filter: [:and, [:oneof, :ref, component_refs],
                 [:eq, DB.parent_field(:library, :component), library_id]]
      }
      cmps = Model.get_objs(cmp_mh, sp_hash)

      sp_hash = {
        cols: [:id],
        filter: [:and, [:eq, :display_name, impl_name],
                 [:eq, DB.parent_field(:library, :implementation), library_id]]
      }
      impl_id = Model.get_objs(library_idh.createMH(:implementation), sp_hash).first[:id]

      update_rows = cmps.map do |cmp|
        {
          id: cmp[:id],
          implemtation_id: impl_id
        }
      end
      Model.update_from_rows(cmp_mh, update_rows)
    end
  end
end
