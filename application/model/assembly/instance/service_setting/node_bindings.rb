module DTK
  class ServiceSetting
    class NodeBindings < Array
      def self.each_element(content,&block)
        pp [NodeBindings,content]
      end
      class Element
      end
    end
  end
end
