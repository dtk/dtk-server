module DTK; class ModuleRefs
  class Tree
    class Collapsed < Hash
      Element = Struct.new(:module_name,:namespace,:level,:implementation_id)

      module Mixin
        def collapse(opts={})
          ret = Collapsed.new
          level = opts[:level] || 1
          @module_refs.each_pair do |module_name,subtree|
            unless namespace = subtree.namespace?() 
              Log.error("Unexpected that no namespace info")
              next
            end
            
            (ret[module_name] ||= Array.new) << Element.new(module_name,namespace,level,nil)
            
            # process sub tree
            subtree.collapse(:level => level+1).each_pair do |subtree_module_name,subtree_els|
              collapsed_tree_els = ret[subtree_module_name] ||= Array.new
              subtree_els.each do |subtree_el|
                unless collapsed_tree_els.find{|el|el == subtree_el}
                  collapsed_tree_els << subtree_el
                end 
              end
            end
          end
          ret
        end
      end

      # opts[:stratagy] can be
      #  :pick_first_level - if multiple and have first level one then use that otherwise will randomly pick top one
      def choose_namespaces!(opts={})
        strategy = opts[:strategy] || DefaultStrategy
        if strategy == :pick_first_level
          choose_namespaces__pick_first_level!()
        else
          raise Error.new("Curerntly not supporting namespace resolution strategy '#{strategy}'")
        end
      end
      DefaultStrategy = :pick_first_level

     private
      def choose_namespaces__pick_first_level!(opts={})
        each_pair do |module_name,els|
          if els.size > 1
            first_el = els.sort{|a,b| a.level <=> b.level}.first
            #warning only if first_el does not have level 1 and multiple namesapces
            unless first_el.level == 1 
              namespaces = els.map{|el|el.namespace}.uniq
              if namespaces.size > 1
                Log.error("Multiple namespaces (#{namespaces.join(',')}) for '#{module_name}'; picking one '#{first_el.namespace}'")
              end
            end
            self[module_name] = [first_el]
          end
        end
        self
      end

    end
  end
end; end
