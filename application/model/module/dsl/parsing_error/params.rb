module DTK
  module ModuleDSL
    class ParsingError
      class Params < Hash
        def initialize(hash={})
          super()
          replace(hash)
        end
        
        #array can have as last element a Params arg
        def self.add_to_array(array,hash_params)
          if array.last().kind_of?(Params)
            array[0...array.size-1] + [array.last().dup.merge(hash_params)]
          else
            array + [new(hash_params)]
          end
        end
      end
    end
  end
end
