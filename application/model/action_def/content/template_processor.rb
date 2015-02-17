module DTK; class ActionDef; class Content
  class TemplateProcessor
    # TODO: hard wired in mustache
    r8_nested_require('template_processor/adapter','mustache_template')
    def self.default()
      # For Rich: needed to change from Mustache to MustacheTemplate because Mustache class name is reserved by mustache gem
      MustacheTemplate.new()
    end
  end
end; end; end
