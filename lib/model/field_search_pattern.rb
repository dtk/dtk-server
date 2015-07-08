# TODO: see if can collapse or better integrate with dataset_from_search_pattern.rb
module XYZ
  module FieldSearchPatternInstanceMixin
    class FieldSearchPattern
      def initialize(model_name,field_set_class)
        @col_basic_types = ColumnTypeCache[model_name] ||= field_set_class.scalar_cols_with_types(model_name).inject({}){|h,nt|h.merge(nt[0] => BasicTypeMapping[nt[1]])}
      end

      def ret_where_clause_for_search_string(name_value_pairs)
        ret = nil
        name_value_pairs.each do |name_x,value|
          name = name_x.to_sym
          # ignore if empty
          next if (value && value.empty?)
          # ignore unless column has a basic type
          basic_type = @col_basic_types[name]
          next unless basic_type
          new_el =
            if value.nil? || value == "UNSET"
              {name => nil}
            else
              case basic_type
               when :string
                SQL::WhereCondition.like(name,"#{value}%")
               when :numeric
                process_numeric(name,value)
               when :boolean
                {name => (value == 1 || value == "1") ? true : false}
              end
          end
          ret = SQL.and(ret,new_el)
        end
        ret
      end

      private

      def process_numeric(name,value)
        # TODO: may encapsulate undet SQL class
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

      ColumnTypeCache = {}
      BasicTypeMapping = {
        string: :string,
        text: :string,
        varchar: :string,
        bigint: :numeric,
        integer: :numeric,
        int: :numeric,
        numeric: :numeric,
        boolean: :boolen
      }
    end
  end
end
