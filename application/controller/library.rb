# TODO: Marked for removal [Haris]
module DTK
  class LibraryController < AuthController

    def rest__info_about()
      library = create_obj(:library_id)
      about = ret_non_null_request_params(:about).to_sym
      rest_ok_response library.info_about(about)
    end

  end
end
