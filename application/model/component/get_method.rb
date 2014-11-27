# TOIDO: wil move get methods taht wil not be deprecating to here or some file underneath a file directory
module DTK; class Component
  module GetMethod
    module Mixin
      def get_augmented_link_defs()
        ndx_ret = Hash.new
        get_objs(:cols => [:link_def_links]).each do |r|
          link_def =  r[:link_def]
          pntr = ndx_ret[link_def[:id]] ||= link_def.merge(:link_def_links => Array.new)
          pntr[:link_def_links] << r[:link_def_link]
        end
        ret =  ndx_ret.values()
        ret.each{|r|r[:link_def_links].sort!{|a,b|a[:position] <=> b[:position]}}
        ret
      end
      
      def get_node()
        get_obj_helper(:node)
      end
    end
    
    module ClassMixin
      def get_include_modules(component_idhs,opts={})
        sp_hash = {
          :cols => opts[:cols] || IncludeModule.common_columns()+(opts[:cols_plus]||[]),
          :filter => [:oneof,:component_id,component_idhs.map{|idh|idh.get_id()}]
        }
        incl_mod_mh = component_idhs.first.createMH(:component_include_module)
        get_objs(incl_mod_mh,sp_hash)
      end
    end
  end
end; end


