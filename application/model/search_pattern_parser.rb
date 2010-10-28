#TODO: should this be in model subdirectory?
#TODO: is theer any advatange to this being a sub class of a Hash?
require File.expand_path(UTILS_DIR+'/internal/generate_list_meta_view')
module XYZ
  class SearchPattern < HashObject
    def initialize(hash_search_pattern)
      super()
      pares_and_set!(hash_search_pattern)
    end

    def field_set()
      #TBD: stub; must take out non scalars
      (columns ? Model::FieldSet.new(columns) : nil) || (relation.kind_of?(Symbol) ? Model::FieldSet.default(relation) : nil)
    end

    def is_default_view?()
      (columns.nil? and filter.nil? and relation.kind_of?(Symbol)) ? true : nil
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
   private
    include GenerateListMetaView

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
    end

    def ret_relation(hash_input)
      relation_str = find_key_from_input(:relation,hash_input)
      return nil unless relation_str
      ret_symbol(relation_str)
    end

    def ret_columns(hash_input)
      columns = find_key_from_input(:columns,hash_input)
      return nil if columns.nil? or columns.empty?
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
      return nil if filter.nil? or filter.empty?

      #TODO: just treating some subset of patterns
      ret = Array.new
      if filter.kind_of?(Array)
        op,args = get_op_and_args(filter)
        raise ErrorPatternNotImplemented.new(:filter_operation,op) unless (op == :and)
        ret << op
        args.each do |el|
          el_op,el_args = get_op_and_args(el)
          #TODO: just treating eq
          raise ErrorPatternNotImplemented.new(:equal_op,el) unless (el_op == :eq and el_args.size == 2)
          ret << ([el_op] + el_args.map{|x|ret_scalar(x)})
        end
      else
        raise ErrorPatternNotImplemented.new(:filter,filter)
      end
      ret
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
