
require File.expand_path('field.text.rb', File.dirname(__FILE__))

class Fieldactions_basic < Fieldbase
  def initialize(field_meta)
    super(field_meta)
  end

  def get_field_list_rtpl
    field_string = ''

    @field_meta[:action_list].each do |action|
      field_string != '' ? field_string << @field_meta[:action_seperator] : nil
      label = '{%=_' << @model_name << '[:i18n][:' << action[:label] << ']%}'

      (!action[:target].nil? && action[:target] != '') ? target = 'target="' + action[:target] + '"' : target = ''
      field_string << '<a href="' << R8::Config[:base_uri] << '/xyz/' << action[:route] << '"' << target << '>' << label << '</a>'
    end

    field_string
  end
end
