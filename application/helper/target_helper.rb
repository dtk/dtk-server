module Ramaze::Helper
  module TargetHelper

    def ret_target_subtype()
      (ret_request_params(:subtype)||:instance).to_sym
    end

    def extract_hash(original_hash, *params)
      params.inject(Hash.new) do |h,p|
        val = original_hash[p.to_sym]
        (val ? h.merge(p.to_sym => val) : h)
      end
    end
  end
end