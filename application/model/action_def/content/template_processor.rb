module DTK; class ActionDef; class Content
  class TemplateProcessor
    # TODO: hard wired in mustache
    r8_nested_require('template_processor/adapter','mustache')
    def self.default()
      Mustache.new()
    end
  end
end; end; end
