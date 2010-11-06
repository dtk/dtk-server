#TODO: should this be in model subdirectory?
require File.expand_path(UTILS_DIR+'/internal/generate_list_meta_view')
module XYZ
  class SearchPattern < HashObject
    def self.create(hash_search_pattern)
      #TODO: case on whether simple or complex
      SearchPatternSimple.new(hash_search_pattern)
    end
  end

#TODO: add a more complex search patterm which is joins/link following of simple patterms
  class SearchPatternSimple < SearchPattern
    def initialize(hash_search_pattern)
      super()
      pares_and_set!(hash_search_pattern)
    end
    def hash_for_json_generate()
      ret = process_symbols(self)
      #TODO: would be nice to get rid of this hack
      ret[":relation"] =  ret[":relation"] ? ret[":relation"].gsub(/^:/,"") : nil
      ret
    end
    def field_set()
      #TBD: stub; must take out non scalars
      model_name = relation.kind_of?(Symbol) ? relation : nil
      if columns.empty? 
        model_name ? Model::FieldSet.default(model_name) : nil 
      else
        Model::FieldSet.new(model_name,columns)
      end
    end

    def is_default_view?()
      (columns.empty? and filter.empty? and relation.kind_of?(Symbol)) ? true : nil
    end

    def find_key(type)
      find_key_from_input(type,self)
    end

    def order_by()
      self[:order_by]
    end
    def relation()
      self[:relation]
    end
    def paging()
      self[:paging]
    end

    def create_list_view_meta_hash()
      #TODO: this is very simple; this will be enhanced
      generate_list_meta_view(columns,relation)
    end
    
    def ret_form_for_db()
      process_symbols(self)
    end
   private
    include GenerateListMetaView

    def process_symbols(obj)
      if obj.kind_of?(Array)
        obj.map{|x|process_symbols(x)}
      elsif obj.kind_of?(Hash)
        obj.inject({}){|h,kv|h.merge(process_symbols(kv[0]) => process_symbols(kv[1]))}
      elsif obj.kind_of?(Symbol)
        ":#{obj}"
      else
        obj
      end
    end


    def find_key_from_input(type,hash_input)
      pair = hash_input.find{|k,v|ret_symbol(k) == type}
      pair ? pair[1] : nil
    end

    def columns()
      self[:columns]
    end
    def filter
      self[:filter]
    end

    def pares_and_set!(hash_input)
      self[:relation] = ret_relation(hash_input)
      self[:columns] = ret_columns(hash_input)
      self[:filter] = ret_filter(hash_input)
      self[:order_by] = ret_order_by(hash_input)
      self[:paging] = ret_paging(hash_input)
    end

    def ret_relation(hash_input)
      relation_str = find_key_from_input(:relation,hash_input)
      return nil unless relation_str
      ret_symbol(relation_str)
    end

    def ret_columns(hash_input)
      columns = find_key_from_input(:columns,hash_input)
      return Array.new if columns.nil? or columns.empty?
      raise ErrorParsing.new(:columns,columns) unless columns.kind_of?(Array)
      #form will be an array with each term either token or {:foo => :alias}; 
      #TODO: right now only treating col as string or term
      columns.map do |col| 
        if col.kind_of?(Symbol) or col.kind_of?(String)
          ret_symbol(col)
        elsif col.kind_of?(Hash) and col.size = 1
          {ret_symbol(ret_symbol_key(col)) => ret_symbol(Aux::ret_value(col))}
        else
          raise ErrorPatternNotImplemented.new(:column,col)
        end
      end
    end

    def ret_filter(hash_input)
      filter = find_key_from_input(:filter,hash_input)
      return Array.new if filter.nil? or filter.empty?

      #TODO: just treating some subset of patterns
      ret = Array.new
      if filter.kind_of?(Array)
        op,args = get_op_and_args(filter)
        raise ErrorPatternNotImplemented.new(:filter_operation,op) unless (op == :and)
        ret << op
        args.each do |el|
          el_op,el_args = get_op_and_args(el)
          raise ErrorParsing.new(:expression_arguments,el_args) unless el_args.size == 2
          raise ErrorPatternNotImplemented.new(:filter_operation,el_op) unless FilterOperationsParsed.include?(el_op)
          if el_op == :oneof
            raise ErrorParsing.new(:argument_to_one_of,el_args[1]) unless el_args[1].kind_of?(Array)
            ret << [el_op,ret_scalar(el_args[0]),el_args[1]]
          else
            ret << ([el_op] + el_args.map{|x|ret_scalar(x)})
          end
        end
      else
        raise ErrorPatternNotImplemented.new(:filter,filter)
      end
      ret
    end
    FilterOperationsParsed = [:eq, :lt, :lte, :gt, :gte, "match-prefix".to_sym, :regex, :oneof] #TODO: just partial list

    def ret_order_by(hash_input)
      order_by = find_key_from_input(:order_by,hash_input)
      return Array.new if order_by.nil? or order_by.empty?
      raise ErrorParsing.new(:order_by,order_by) unless order_by.kind_of?(Array)
      order_by.map do |el|
        raise ErrorParsing.new(:order_by_element,el) unless el.kind_of?(Hash) and el.size <= 2
        field = (el.find{|k,v|ret_symbol(k) == :field}||[nil,nil])[1]
        raise ErrorParsing.new(:order_by_element,el) unless field 
        order = (el.find{|k,v|ret_symbol(k) == :order}||[nil,"ASC"])[1]
        raise ErrorParsing.new(:order_by_order_direction,order) unless ["ASC","DESC"].include?(order)
        {:field => ret_symbol(field), :order => order}
      end
    end

    def ret_paging(hash_input)
      paging = find_key_from_input(:paging,hash_input)
      return Hash.new if paging.nil? or paging.empty?
      raise ErrorParsing.new(:paging,paging) unless paging.kind_of?(Hash) and paging.size <= 2
      start = (paging.find{|k,v|ret_symbol(k) == :start}||[nil,nil])[1]
      raise ErrorParsing.new(:paging_start,paging) unless start 
      limit = (paging.find{|k,v|ret_symbol(k) == :limit}||[nil,nil])[1]
      {:start => start.to_i}.merge(limit ? {:limit => limit.to_i} : {})
    end

    #return op in symbol form and args
    def get_op_and_args(expr)
      raise ErrorParsing.new(:expression,expr) unless expr.kind_of?(Array)
      [ret_symbol(expr.first),expr[1..expr.size-1]]
    end

    #converts if symbol still in string form; otehrwise keeps as string
    def ret_symbol(term_in_json)
      #TODO short circuit if parsed already
      raise ErrorParsing.new(:symbol,term_in_json) if [Array,Hash].detect{|t|term_in_json.kind_of?(t)}
      #complexity due to handle case where have form :":columns"
      term_in_json.to_s.gsub(/^[:]+/,'').to_sym 
    end
    
    def ret_scalar(term_in_json)
      raise ErrorParsing.new(:symbol,term_in_json) if [Array,Hash].detect{|t|term_in_json.kind_of?(t)}
      #complexity due to handle case where have form :":columns"
      return term_in_json.to_s.gsub(/^[:]+/,'').to_sym if term_in_json.kind_of?(Symbol)
      return $1.to_sym if (term_in_json.kind_of?(String) and term_in_json =~ /^[:]+(.+)/)
      term_in_json
    end

    def ret_symbol_key(obj)
      ret_symbol(Aux::ret_key(obj))
    end

    class ErrorParsing < Error
      def initialize(type,object)
        super("parsing item #{type} is not supported; it has form: #{object.inspect}")
      end
    end
    class ErrorPatternNotImplemented < ErrorNotImplemented
      def initialize(type,object)
        super("parsing item #{type} is not supported; it has form: #{object.inspect}")
      end
    end
  end
end
