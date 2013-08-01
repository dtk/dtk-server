module DTK
  module AttributeGuardClassMixin

   private
    #TODO: may deprecate; have another fn that does this check for assembly insatnces
    def ret_required_attrs_without_values(augmented_attr_list,guards)
      #TODO: determine if guards test is needed in addition to required_unset_attribute?() test
      guarded_ids = nil
      violation_errs = ErrorsUsage.new
      augmented_attr_list.each do |aug_attr|
        if aug_attr.required_unset_attribute?()
          guarded_ids ||= guards.map{|g|g[:guarded][:attribute][:id]}.uniq
          unless guarded_ids.include?(aug_attr[:id])
            violation_errs << Violation::MissingRequiredAttribute.new(aug_attr)
          end
        end
      end
      violation_errs.empty? ? nil : violation_errs
    end
  end
end
