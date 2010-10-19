module XYZ
  module FieldSearchPatternInstanceMixin
    class FieldSearchPattern
      def initialize(model_name,field_set_class)
        @col_basic_types = ColumnTypeCache[model_name] ||= field_set_class.real_cols_with_types(model_name).inject({}){|h,nt|h.merge(nt[0] => BasicTypeMapping[nt[1]])}
      end
      def ret_where_clause_for_search_string(name_value_pairs)
        name_value_pairs.inject({}) do |ret,nv|
          name_x,value = nv
          name = name_x.to_sym
          #ignore if empty 
          next if value.empty?
          #ignore unless column has a basic type
          basic_type = @col_basic_types[name]
          next unless basic_type
          new_el = 
            case basic_type
             when :string
              SQL::WhereCondition.like(name,"#{value}%")
             when :numeric
              process_numeric(name,value)
             when :boolean
              {name => (value == 1 or value == "1") ? true : false}
          end
          ret = SQL.and(ret,new_el)
        end
      end
     private
      def process_numeric(name,value)
        #TODO: may encapsulate undet SQL class
        if value =~ /^<=(.+)$/
          name.to_s.lit <= $1
        elsif value =~ /^>=(.+)$/
          name.to_s.lit >= $1
        elsif value =~ /^<(.+)$/
          name.to_s.lit < $1
        elsif value =~ /^>(.+)$/
          name.to_s.lit > $1
        else
          {name => value}
        end
      end

      ColumnTypeCache = Hash.new
      BasicTypeMapping = {
        :string => :string,
        :text => :string,
        :varchar => :string,
        :bigint => :numeric,
        :integer => :numeric, 
        :int => :numeric, 
        :numeric => :numeric,
        :boolean => :boolen
      }
    end
  end
end
