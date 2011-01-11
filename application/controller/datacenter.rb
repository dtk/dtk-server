module XYZ
  class DatacenterController < Controller
    def create(name)
      c = ret_session_context_id()
      Datacenter.create(name,c)
      "datacenter created with name #{name}"
    end
  end
end
