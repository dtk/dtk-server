{
  :schema=>:gitolite,
  :table=>:repo,
  :columns=>{
    :path => {:type=>:varchar, :size => 100}
  },
  :one_to_many=> [:gitolite_user]
}
