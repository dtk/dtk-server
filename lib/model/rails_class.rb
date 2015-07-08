#
# Set of methods that expend from Rails ActiveRecord model
#

module DTK
  DTK_C = 2

  module RailsClass
    def all
      get_objs(resolve_mh(),{})
    end

    def create_simple(hash, user)
      create_from_rows(resolve_mh(user), [hash], convert: true, do_not_update_info_table: true)
    end

    def where(sp_hash)
      get_objs(resolve_mh, sp_hash)
    end

    private

    def resolve_mh(user=nil)
      mh = DTK::ModelHandle.new(DTK_C, model_handle_id(), nil, user)
      mh
    end

    def model_handle_id
      clazz_name = self.to_s.split('::').last
      clazz_name.gsub(/(.)([A-Z])/,'\1_\2').downcase
    end
  end
end
