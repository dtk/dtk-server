{
  :schema=>:namespace,
  :table=>:namespace,
  :columns=>{
    :name => { :type => :varchar, :size => 50 },
    :remote => { :type => :varchar, :size => 50 },
    },
  :virtual_columns=>{},
  :one_to_many=>[:component, :service]
}
