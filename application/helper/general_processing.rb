module Ramaze::Helper
  module GeneralProcessing
    def ret_session_context_id
      # stub
      2
    end

    ### user processing
    def login_first
      auth_violation_response() unless logged_in?
    end

    def auth_violation_response
      rest_request? ? respond('Forbidden', 403) : redirect(R8::Config[:login][:path])
    end

    def auth_unauthorized_response(message)
      rest_request? ? respond(message, 401) : redirect(R8::Config[:login][:path])
    end

    def auth_forbidden_response(message)
      rest_request? ? respond(message, 403) : redirect(R8::Config[:login][:path])
    end

    def get_user
      return nil unless user.is_a?(Hash)
      @cached_user_obj ||= User.new(user, ret_session_context_id(), :user)
    end

    class UserContext
      attr_reader :current_profile, :request, :json_response

      def initialize(controller)
        @current_profile = :default
        @request = controller.request
      @json_response = controller.json_response?
        @controller = controller
      end

      def create_object_from_id(id)
        @controller.create_object_from_id(id)
      end
    end
    ##############

    def initialize
      super
      @cached_user_obj = nil
      # TODO: see where these are used; remove if not used
      @public_js_root = R8::Config[:public_js_root]
      @public_css_root = R8::Config[:public_css_root]
      @public_images_root = R8::Config[:public_images_root]

      # TBD: may make a calls fn that declares a cached var to be 'self documenting'
      @model_name = nil #cached ; called on demand

      # used when action set calls actions
      @parsed_query_string = nil

      @css_includes = []
      @js_includes = []
      @js_exe_list = []

      @user_context = nil

      @layout = nil

      # if there is an action set then call by value is used to substitue in child actions; this var
      # will be set to have av pairs set from global params given in action set call
      @action_set_param_map = {}

      @ctrl_results = nil
    end

    def json_response?
      @json_response ||= rest_request?() or ajax_request?()
    end

    def rest_request?
      # TODO: needs to be fixed up; issue is different envs (linux versus windows) give different values for request.env["REQUEST_URI"]
      @rest_request ||= (request.env['REQUEST_URI'] =~ Regexp.new('/rest/') ? true : nil)
    end

    def ajax_request?
      @ajax_request ||= ajax_request_aux?()
    end

    def ajax_request_aux?
      route_pieces = request.env['PATH_INFO'].split('/')
      last_piece = route_pieces[route_pieces.size - 1]
      return true if /\.json/.match(last_piece)

      return true if request.params['iframe_upload'] == '1'

      (request.env['HTTP_X_REQUESTED_WITH'] && request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest')
    end
  end
end
