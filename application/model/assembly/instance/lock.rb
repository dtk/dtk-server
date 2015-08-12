module DTK; class Assembly; class Instance
  class Lock < Model
    def self.common_columns
      [:id, :display_name, :group_id, :module_name, :module_namespace, :service_module_sha, :created_at]
    end

    attr_accessor :assembly_instance, :service_module_name, :service_module_namespace, :service_module_sha
    def initialize(*args, &block)
      super
      @assembly_instance = nil
      @service_module_name = nil
      @service_module_namespace = nil
      @service_module_sha = nil
    end

    def self.create_from_element(assembly_instance, service_module)
      ret = create_stub(assembly_instance.model_handle(:assembly_instance_lock))
      ret.assembly_instance = assembly_instance
      ret.service_module_name = service_module[:display_name]
      ret.service_module_namespace = service_module.module_namespace
      ret.service_module_sha = service_module.get_augmented_workspace_branch.get_field?(:current_sha)
      ret
    end

    def save_to_model()
      db_update_hash = DBUpdateHash.new()
      hash_body = {
        display_name: @assembly_instance[:display_name],
        module_name: @service_module_name,
        module_namespace: @service_module_namespace,
        service_module_sha: @service_module_sha,
        created_at: Aux.now_time_stamp()
      }
      hash = { @assembly_instance[:display_name] => hash_body }
      db_update_hash.merge!(hash)
      db_update_hash.mark_as_complete()
      assembly_instance_idh = @assembly_instance.id_handle()
      Model.input_hash_content_into_model(assembly_instance_idh, assembly_instance_lock: db_update_hash)
    end

    def self.get(assembly_instance)
      sp_hash = {
        cols: Lock.common_columns(),
        filter: [:eq, :component_id, assembly_instance.id]
      }
      Model.get_obj(assembly_instance.model_handle(:assembly_instance_lock), sp_hash)
    end
  end
end; end; end