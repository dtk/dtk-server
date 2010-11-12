#TODO: just stubbing now with cached hashes
module XYZ
  class AttributeComplexType < Model
    set_relation_name(:attribute,:complex_type)
    def self.up()
    end
    #helper fns
    def self.has_required_fields_given_semantic_type?(obj,semantic_type)
      required_pat = Required[semantic_type]
      return nil unless required_pat
      has_required_fields?(obj,required_pat)
    end
   private
    #TODO: stub
    Required = 
      {
      "sap_config" => {
        :array => {
          "type" =>  true,
          "port" => true,
          "protocol" => true
        }
      },
      "sap" => {
        :array => {
          "type" =>  true,
          "port" => true,
          "protocol" => true,
          "host" => true,
        }
      },
      "db_info" => {
        :array => {
          "username" =>  true,
          "database" => true,
          "password" => true
        }
      }

    }

    def self.has_required_fields?(obj,pattern)
      #care must be taken to make thsi three-valued
      if obj.kind_of?(Array)
        array_pat = pattern[:array]
        if array_pat
          return false if obj.empty? 
          obj.each do |el|
            ret = has_required_fields?(el,array_pat)
            return ret unless ret.kind_of?(TrueClass)
          end
          return true
        end
        Log.error("mismatch between object #{obj.inspect} and pattern #{pattern}")
      elsif obj.kind_of?(Hash)
        if pattern[:array]
          Log.error("mismatch between object #{obj.inspect} and pattern #{pattern}")
          return nil
        end
        pattern.each do |k,child_pat|
          el = obj[k.to_sym]
          return false unless el
          next if child_pat.kind_of?(TrueClass)
          ret = has_required_fields?(el,child_pat)
          return ret unless ret.kind_of?(TrueClass) 
        end
        return true
      else
        Log.error("mismatch between object #{obj.inspect} and pattern #{pattern}")
      end
      nil
    end


  end
end
