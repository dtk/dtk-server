module DTK; class ActionDef; class Content
  class TemplateProcessor
    # TODO: hard wired in mustache
    r8_nested_require('template_processor/adapter','mustache_template')
    def self.default()
      MustacheTemplate.new()
    end
  end
end; end; end
