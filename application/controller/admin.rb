

module XYZ
  class AdminController < Controller

    #TODO: figure out proper place/naming for function calls for db install/setup steps
    def dbrebuild
      Model.db_rebuild(DBinstance)
      "database rebuild finished"
    end
  end
end
