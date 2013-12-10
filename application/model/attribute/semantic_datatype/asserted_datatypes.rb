#TODO: modify so that types like port can call tehir parents methods
module DTK; class Attribute 
  class SemanticDatatype
    Type :object do
      basetype :json
    end
    Type :array do
      basetype :json
      validation lambda{|v|v.kind_of?(Array)}
    end
    Type :hash do
      basetype :json
      validation lambda{|v|v.kind_of?(Hash)}
    end
    Type :port do
      basetype :integer
      validation /^[0-9]+$/
      internal_form lambda{|v|v.to_i}
    end
    Type :log_file do
      basetype :string
      validation /.*/ #so checks taht it is scalar
    end

    #base types
    Type :string do
      basetype :string
      validation /.*/ #so checks taht it is scalar 
    end
    Type :integer do
      basetype :integer
      validation /^[0-9]+$/
      internal_form lambda{|v|v.to_i}
    end
    Type :boolean do
      basetype :boolean
      validation /true|false/
      internal_form lambda{|v|
        if v.kind_of?(TrueClass) or v == 'true'
          true
        elsif v.kind_of?(FalseClass) or v == 'false'
          false
        else
          raise Error.new("Bad boolean type (#{v.inspect})") #this should not be reached since v is validated before this fn called
        end
      }
    end
    #TODO: may deprecate
    Type :json do
      basetype :json
    end
  end
end; end
    
