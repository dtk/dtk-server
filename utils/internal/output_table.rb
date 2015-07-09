module DTK
  class OutputTable
    def self.join(main_table, join_columns, &main_table_sort)
      # shortcut
      if join_columns.empty?
        return main_table.sort(&main_table_sort)
      end

      # TODO: see if any better way than embedding, sorting, then expanding
      embed = []
      main_table.each_with_index do |r, i|
        if jc = join_columns[i]
          embed << r.merge('__jc' => jc)
        else
          embed << r
        end
      end
      ret = []
      embed.sort(&main_table_sort).each do |r|
        if jc = r.delete('__jc')
          ret << r.merge(jc.first)
          ret += jc[1..jc.size] if jc.size > 1
        else
          ret << r
        end
      end
      ret
    end

    class JoinColumns < Hash
      def initialize(raw_rows, &block)
        # dont put in super() because is passes in &block
        raw_rows.each_with_index do |raw_row, i|
          if join_for_i = block.call(raw_row)
            unless join_for_i.empty?
              merge!(i => join_for_i)
            end
          end
        end
      end
    end
  end
end
