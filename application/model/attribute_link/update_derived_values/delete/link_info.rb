module DTK; class AttributeLink; class UpdateDerivedValues
  class Delete
    class LinkInfo
      attr_reader :input_attribute, :deleted_links, :other_links
      def initialize(input_attribute)
        @input_attribute = input_attribute
        @deleted_links = []
        @other_links = []
      end
      
      def add_other_link!(link)
        @other_links << link unless match?(@other_links, link)
      end
      
      def add_deleted_link!(link)
        @deleted_links << link unless match?(@deleted_links, link)
      end

      private
      
      def match?(links, link)
        attribute_link_id = link[:attribute_link_id]
        links.find { |l| l[:attribute_link_id] == attribute_link_id }
      end

    end
  end
end; end; end
