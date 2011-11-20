def r8_require(*files_x)
  files = (files_x.first.kind_of?(Array) ? files_x.first : files_x) 
  caller_dir = caller.first.gsub(/\/[^\/]+$/,"")
  files.each{|f|require File.expand_path(f,caller_dir)}
end
def r8_nested_require(dir,*files_x)
  files = (files_x.first.kind_of?(Array) ? files_x.first : files_x) 
  caller_dir = caller.first.gsub(/\/[^\/]+$/,"")
  files.each{|f|require File.expand_path("#{dir}/#{f}",caller_dir)}
end
def r8_nested_require_with_caller_dir(caller_dir,dir,*files_x)
  files = (files_x.first.kind_of?(Array) ? files_x.first : files_x) 
  files.each{|f|require File.expand_path("#{dir}/#{f}",caller_dir)}
end
