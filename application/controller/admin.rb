

module XYZ
  class AdminController < AuthController

    # TODO: figure out proper place/naming for function calls for db install/setup steps
    def dbrebuild
      Model.db_rebuild(:db => DBinstance)
      "database rebuild finished"
    end
  end
end
