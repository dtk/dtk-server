
{
  :impelements_owner=>true,
#  :has_ancestor_fields=>true,
  :extends_base_model=>true,
  :extends_component_model => true,
  :field_defs=>{
    :name=>{
      :type=>:text,
      :size=>50
    },
    :parent_name=>{
      :type=>:text
    },
    :parent_id=>{
      :type=>:foo
    },
    :type=>{
      :type=>:varchar,
      :size=>15
    },
    :basic_type=>{
      :type=>:select,
      :size=>15
    },
    :has_pending_change=>{
      :type=>:boolean,
    },
    :version=>{
      :type=>:text,
      :size=>25,
    },
#begin attribute fields
    :ServerAdmin=> {
      :type => :varchar,
      :size=>50
    },
    :ServerName=> {
      :type => :varchar,
      :size=>100
    },
    :DocumentRoot => {
      :type => :varchar,
      :size=>100
    },
    :ErrorLog => {
      :type => :varchar,
      :size=>100
    },
    :LogLevel => {
      :type => :varchar,
      :size=>100
    }
  },
  :relationships=>{
  }
}

