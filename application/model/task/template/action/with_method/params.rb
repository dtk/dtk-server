module DTK; class Task::Template::Action::WithMethod
  module Params
    # Returns an attribute - value hash
    def self.parse(serialized_item)
      ret = {}
      attr_val_array = serialized_item.split(',').map { |attr_val| parse_attribute_value_pair?(attr_val) }.compact

      # check for dups and convert to attribute value hash
      count = {}
      attr_val_array.each do |attr_val|
        name, value = attr_val
        count[name] ||= 0
        count[name] += 1
        ret.merge!(name => value)
      end
      if count.values.find { |v| v > 1 }
        fail ParsingError, "The same parameter is assigned multiple times in: #{serialized_item}"
      end
      ret
    end
    
    private
    
    # returns [attr_name, attr_value]
    def self.parse_attribute_value_pair?(attr_val)
      return nil if attr_val.empty?
      unless attr_val =~ /(^[^=]+)=([^=]+$)/
        fail ParsingError, "The parameter assignment (#{attr_val}) is ill-formed"
      end
      name = remove_preceding_and_trailing_spaces(Regexp.last_match(1))
      value = remove_preceding_and_trailing_spaces(Regexp.last_match(2))
      [name, value]
    end

    def self.remove_preceding_and_trailing_spaces(str)
      str.gsub(/^[ ]+/,'').gsub(/[ ]+$/,'')
    end
  end
end; end
