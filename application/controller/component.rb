# TODO: Marked for removal [Haris]
module DTK
  class ComponentController < AuthController
    helper :assembly_helper

    def rest__list
      project = get_default_project()
      ignore = ret_request_params(:ignore)
      assembly_instance = ret_assembly_instance_object?()
      opts = Opts.new()
      opts.merge?(assembly_instance: assembly_instance)
      opts.merge?(ignore: ignore)
      rest_ok_response Component::Template.list(project,opts)
    end
  end
end
