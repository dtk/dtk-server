#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# TODO: replace with relative dir
r8_require("#{UTILS_DIR}/generate_list_meta_view")
module XYZ
  class SearchPattern < HashObject
    def self.create(hash_search_pattern)
      # TODO: case on whether simple or complex
      SearchPatternSimple.new(hash_search_pattern)
    end
    def self.create_just_filter(hash_search_pattern)
      SearchPatternSimple.new(hash_search_pattern, keys: [:filter])
    end
    def self.process_symbols(obj)
      if obj.is_a?(Array)
        obj.map { |x| process_symbols(x) }
      elsif obj.is_a?(Hash)
        obj.inject({}) { |h, kv| h.merge(process_symbols(kv[0]) => process_symbols(kv[1])) }
      elsif obj.is_a?(Symbol)
        ":#{obj}"
      else
        obj
      end
    end
  end

  module HashSearchPattern
    # TODO: should unify with parsing in utils/internal/dataset_from_search_pattern.rb; and may do away with having to deal with symbol and variant forms
    def self.add_to_filter(hash_search_pattern, hash_filter)
      filter = augment_filter(index(hash_search_pattern, :filter), hash_filter)
      merge(hash_search_pattern, filter: filter)
    end

    private

    def self.augment_filter(hash_filter, hash_filter_addition)
      to_add = [hash_filter_addition]
      if hash_filter.nil?
        [:and] + to_add
      elsif match(hash_filter.first, :and)
          hash_filter + to_add
      else
        [:and] + [hash_filter] + to_add
      end
    end

    def self.symbol_persistent_form(symbol, opts = {})
      opts[:is_symbol] ? ":#{symbol}".to_sym : ":#{symbol}"
    end

    def self.merge(hash, to_add, opts = {})
      to_add.inject(hash) { |h, kv| h.merge(select_index_form(h, kv[0], opts) => kv[1]) }
     end

    def self.select_index_form(hash, symbol_index, opts = {})
      return symbol_index if hash[symbol_index]
      symbol_persistent_form = symbol_persistent_form(symbol_index, opts)
      hash[symbol_persistent_form] ? symbol_persistent_form : symbol_index
    end

    def self.index(hash, symbol_index, opts = {})
      hash[symbol_index] || hash[symbol_persistent_form(symbol_index, opts)]
    end
    def self.match(term, symbol, opts = {})
      term == symbol || term == symbol_persistent_form(symbol, opts)
    end
  end

  # TODO: add a more complex search patterm which is joins/link following of simple patterms
  class SearchPatternSimple < SearchPattern
    def initialize(hash_search_pattern, opts = {})
      super()
      parse_and_set!(hash_search_pattern, opts)
    end

    def self.ret_parsed_comparison(expr)
      (expr[1].is_a?(Symbol) ? { col: expr[1], constant: expr[2] } : { col: expr[2], constant: expr[1] }).merge(op: expr[0])
    end

    def break_filter_into_conjunctions
      return [] if self[:filter].nil? || self[:filter].empty?
      break_into_conjunctions(self[:filter])
    end

    private

    def break_into_conjunctions(expr)
      return [expr] unless expr.first == :and
      expr[1..expr.size - 1].inject([]) do |a, x|
        a + break_into_conjunctions(x)
      end
    end

    public

    def hash_for_json_generate
      ret = process_symbols(self)
      # TODO: would be nice to get rid of this hack
      ret[':relation'] =  ret[':relation'] ? ret[':relation'].gsub(/^:/, '') : nil
      ret
    end

    def related_remote_column_info(vcol_sql_fns = nil)
      field_set().related_remote_column_info(vcol_sql_fns)
    end

    def field_set
      # TBD: stub; must take out non scalars
      model_name = relation.is_a?(Symbol) ? relation : nil
      if columns.empty?
        model_name ? Model::FieldSet.default(model_name) : nil
      else
        Model::FieldSet.new(model_name, columns)
      end
    end

    def is_default_view?
      (columns.empty? && filter.empty? && relation.is_a?(Symbol)) ? true : nil
    end

    def find_key(type)
      find_key_from_input(type, self)
    end

    def order_by
      self[:order_by]
    end

    def relation
      self[:relation]
    end

    def paging
      self[:paging]
    end

    def create_list_view_meta_hash
      # TODO: this is very simple; this will be enhanced
      generate_list_meta_view(columns, relation)
    end

    def ret_form_for_db
      process_symbols(self)
    end

    private

    include GenerateListMetaView
    def process_symbols(obj)
      SearchPattern.process_symbols(obj)
    end

    def find_key_from_input(type, hash_input)
      pair = hash_input.find { |k, _v| ret_symbol(k) == type }
      pair ? pair[1] : nil
    end

    def columns
      self[:columns]
    end

    def filter
      self[:filter]
    end

    def parse_and_set!(hash_input, opts = {})
      self[:relation] = ret_relation(hash_input) unless donot_ret_key([:relation, :model_name], opts)
      self[:columns] = ret_columns(hash_input) unless donot_ret_key([:columns, :cols], opts)
      self[:filter] = ret_filter(hash_input) unless donot_ret_key(:filter, opts)
      self[:order_by] = ret_order_by(hash_input) unless donot_ret_key(:order_by, opts)
      self[:paging] = ret_paging(hash_input) unless donot_ret_key(:paging, opts)
    end

    def donot_ret_key(key_or_keys, opts)
      return nil unless opts[:keys]
      (opts[:keys] & Array(key_or_keys)).empty?
    end

    # TODO: move to using model_name, not relation
    def ret_relation(hash_input)
      relation_str = find_key_from_input(:relation, hash_input) || find_key_from_input(:model_name, hash_input)
      return nil unless relation_str
      ret_symbol(relation_str)
    end

    def ret_columns(hash_input)
      columns = find_key_from_input(:columns, hash_input) || find_key_from_input(:cols, hash_input)
      return [] if columns.nil? || columns.empty?
      fail ErrorParsing.new(:columns, columns) unless columns.is_a?(Array)
      # form will be an array with each term either token or {:foo => :alias};
      # TODO: right now only treating col as string or term
      columns.map do |col|
        if col.is_a?(Symbol) || col.is_a?(String)
          ret_symbol(col)
        elsif col.is_a?(Hash) && col.size == 1
          { ret_scalar(col.keys.first) => ret_symbol(Aux.ret_value(col)) }
        else
          fail ErrorPatternNotImplemented.new(:column, col)
        end
      end
    end

    def ret_filter(hash_input)
      filter = find_key_from_input(:filter, hash_input)
      return [] if filter.nil? || filter.empty?

      # TODO: just treating some subset of patterns
      ret = []
      if filter.is_a?(Array)
        op, args = get_op_and_args(filter)
        if op.nil?
          log_parsing_error_to_skip(:filter_operation, op)
          return ret
        elsif not [:and, :or].include?(op)
          # assume implicit and
          args = [[op] + args]
          op = :and
        end
        ret << op
        args.each do |el|
          el_op, el_args = get_op_and_args(el)
          # processing nested ands and ors
          if [:and, :or].include?(el_op)
            ret << ret_filter(filter: el)
          else
            unless el_op && el_args && el_args.size == 2 && FilterOperationsParsed.include?(el_op)
              log_parsing_error_to_skip(:expression, el)
              next
            end
            if el_op == :oneof
              unless el_args[1].is_a?(Array)
                log_parsing_error_to_skip(:argument_to_one_of, el_args[1])
                next
              end
              ret << [el_op, ret_scalar(el_args[0]), el_args[1]]
            else
              ret << ([el_op] + el_args.map { |x| ret_scalar(x) })
            end
          end
        end
      else
        log_parsing_error_to_skip(:filter, filter)
      end
      ret
    end
    FilterOperationsParsed = [:eq, :neq, :lt, :lte, :gt, :gte, 'match-prefix'.to_sym, :regex, :oneof]

    def ret_order_by(hash_input)
      order_by = find_key_from_input(:order_by, hash_input)
      return [] if order_by.nil? || order_by.empty?
      fail ErrorParsing.new(:order_by, order_by) unless order_by.is_a?(Array)
      order_by.map do |el|
        fail ErrorParsing.new(:order_by_element, el) unless el.is_a?(Hash) && el.size <= 2
        field = (el.find { |k, _v| ret_symbol(k) == :field } || [nil, nil])[1]
        fail ErrorParsing.new(:order_by_element, el) unless field
        order = (el.find { |k, _v| ret_symbol(k) == :order } || [nil, 'ASC'])[1]
        fail ErrorParsing.new(:order_by_order_direction, order) unless ['ASC', 'DESC'].include?(order)
        { field: ret_symbol(field), order: order }
      end
    end

    def ret_paging(hash_input)
      paging = find_key_from_input(:paging, hash_input)
      return {} if paging.nil? || paging.empty?
      fail ErrorParsing.new(:paging, paging) unless paging.is_a?(Hash) && paging.size <= 2
      start = (paging.find { |k, _v| ret_symbol(k) == :start } || [nil, nil])[1]
      fail ErrorParsing.new(:paging_start, paging) unless start
      limit = (paging.find { |k, _v| ret_symbol(k) == :limit } || [nil, nil])[1]
      { start: start.to_i }.merge(limit ? { limit: limit.to_i } : {})
    end

    # return op in symbol form and args
    def get_op_and_args(expr)
      return nil unless expr.is_a?(Array)
      [ret_symbol(expr.first), expr[1..expr.size - 1]]
    end

    # converts if symbol still in string form; otehrwise keeps as string
    def ret_symbol(term_in_json)
      # TODO: short circuit if parsed already
      fail ErrorParsing.new(:symbol, term_in_json) if [Array, Hash].detect { |t| term_in_json.is_a?(t) }
# TODO: remove patch
return :eq if term_in_json == ':'
      # complexity due to handle case where have form :":columns"
      term_in_json.to_s.gsub(/^[:]+/, '').to_sym
    end

    def ret_scalar(term_in_json)
      fail ErrorParsing.new(:symbol, term_in_json) if [Array, Hash].detect { |t| term_in_json.is_a?(t) }
      # complexity due to handle case where have form :":columns"
      return term_in_json.to_s.gsub(/^[:]+/, '').to_sym if term_in_json.is_a?(Symbol)
      return Regexp.last_match(1).to_sym if (term_in_json.is_a?(String) && term_in_json =~ /^[:]+(.+)/)
      term_in_json
    end

    def ret_symbol_key(obj)
      ret_symbol(Aux.ret_key(obj))
    end

    def log_parsing_error_to_skip(type, object)
      Log.error("skipping ill-formed #{type} which has form: #{object.inspect}")
    end
    class ErrorParsing < Error
      def initialize(type, object)
        super("parsing item #{type} is not supported; it has form: #{object.inspect}")
      end
    end
    class ErrorPatternNotImplemented < Error::NotImplemented
      def initialize(type, object)
        super("parsing item #{type} is not supported; it has form: #{object.inspect}")
      end
    end
  end
end