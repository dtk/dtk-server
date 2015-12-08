# TODO: Marked for removal [Haris]
module DTK
  class ComponentController < AuthController
    helper :assembly_helper

    def rest__list
      project           = get_default_project()
      assembly_instance = ret_assembly_instance_object?()

      ignore             = ret_request_params(:ignore)
      hide_assembly_cmps = ret_request_params(:hide_assembly_cmps)

      opts = Opts.new()
      opts.merge?(assembly_instance: assembly_instance)
      opts.merge?(ignore: ignore)
      opts.merge?(hide_assembly_cmps: hide_assembly_cmps) if hide_assembly_cmps

      rest_ok_response Component::Template.list(project, opts)
    end
  end
end
