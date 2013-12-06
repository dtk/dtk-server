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
    end
    Type :boolean do
      basetype :boolean
      validation /true|false/
    end
    #TODO: may deprecate
    Type :json do
      basetype :json
    end
  end
end; end
    
