module DTK; class Clone; class IncrementalUpdate
  module InstancesTemplates
    class Links < Array
      def add?(instances, templates, parent_link)
        # do not add if both instances and templates are empty?
        unless instances.empty? && templates.empty?
          self << Link.new(instances, templates, parent_link)
        end
      end

      def instance_model_handle
        unless link = first()
          raise Error.new('Should not be called if this is empty')
        end
        link.instance_model_handle()
      end
    end
  end
end; end; end
