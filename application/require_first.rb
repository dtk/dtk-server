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
def r8_require_common_lib(*files_x)
  files = (files_x.first.kind_of?(Array) ? files_x.first : files_x)
  common_base_dir = File.expand_path('../../dtk-common/lib',File.dirname(__FILE__))
  files.each{|f|require File.expand_path(f,common_base_dir)}
end
##### TODO: deprecate forp above
def dtk_require(*files_x)
  files = (files_x.first.kind_of?(Array) ? files_x.first : files_x) 
  caller_dir = caller.first.gsub(/\/[^\/]+$/,"")
  files.each{|f|require File.expand_path(f,caller_dir)}
end
def dtk_nested_require(dir,*files_x)
  files = (files_x.first.kind_of?(Array) ? files_x.first : files_x) 
  caller_dir = caller.first.gsub(/\/[^\/]+$/,"")
  files.each{|f|require File.expand_path("#{dir}/#{f}",caller_dir)}
end

def dtk_nested_require_with_caller_dir(caller_dir,dir,*files_x)
  files = (files_x.first.kind_of?(Array) ? files_x.first : files_x) 
  files.each{|f|require File.expand_path("#{dir}/#{f}",caller_dir)}
end
def dtk_require_common_lib(*files_x)
  files = (files_x.first.kind_of?(Array) ? files_x.first : files_x)
  common_base_dir = File.expand_path('../../dtk-common/lib',File.dirname(__FILE__))
  files.each{|f|require File.expand_path(f,common_base_dir)}
end
######

#TODO: deprecate of make thsi applicable to 1.9.3
##### for upgrading to ruby 1.9.2
class Hash
  if RUBY_VERSION == "1.9.2"
    def select192(&block)
      select(&block)
    end
    def find192(&block)
      find(&block)
    end
  else
    def select192(&block)
      select(&block).inject({}){|h,kv|h.merge(kv[0] => kv[1])}
    end
    def find192(&block)
      find(&block).inject({}){|h,kv|h.merge(kv[0] => kv[1])}
    end
  end
end
