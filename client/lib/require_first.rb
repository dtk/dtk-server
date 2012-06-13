module DTK
  module Client
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
  end
end
#TODO: these utils shoudl be common gems
def r8_require_util_library(util_library)
  r8_require("../../utils/internal/#{util_library}")
end
