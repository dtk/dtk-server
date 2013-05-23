module DTK; class LinkDefLink
  class Stub < self
    def initialize(attr_mappings)
      unless attr_mappings.kind_of?(Array)
        attr_mappings = [attr_mappings]
      end
    end
  end
end; end
