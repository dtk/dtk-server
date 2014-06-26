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
  files_x.each { |file| dtk_require_dtk_common_file(file) }
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
  files_x.each { |file| dtk_require_dtk_common_file(file) }
end

# Method will check if there is localy avaialbe l
def dtk_require_common_library()
  
  common_folder = determine_common_folder()

  unless common_folder
    require 'dtk_common'
  else
    dtk_require_dtk_common_file('dtk_common')
  end
end
# determining if dtk-common is locally available



private

POSSIBLE_COMMON_CORE_FOLDERS = ['dtk-common','common','dtk_common']

def dtk_require_dtk_common_file(common_library)
  # use common folder else common gem
  common_folder = determine_common_folder()

  if common_folder
    dtk_require("../../" + common_folder + "/lib/#{common_library}")
  elsif is_dtk_common_gem_installed?       
    # already loaded so do not do anything
  else
    raise DTK::Client::DtkError,"Common directory/gem not found, please make sure that you have cloned dtk-common folder or installed dtk common gem!"
  end
end


def gem_only_available?()
  return !determine_common_folder() && is_dtk_common_gem_installed?
end

##
# Check if dtk-common gem has been installed if so use common gem. If there is no gem
# logic from dtk_require_dtk_common will try to find commond folder.
# DEVELOPER NOTE: Uninstall dtk-common gem when changing dtk-common to avoid re-building gem.
def is_dtk_common_gem_installed?
  begin
    # if no exception gem is found
    gem 'dtk-common'
    return true
  rescue Gem::LoadError
    return false
  end
end

##
# Checks for expected names of dtk-common folder and returns name of existing common folder
def determine_common_folder
  POSSIBLE_COMMON_CORE_FOLDERS.each do |folder|
    path = File.join(File.dirname(__FILE__),'..','..',folder)
    return folder if File.directory?(path)
  end

  return nil
end
######

# TODO: deprecate of make thsi applicable to 1.9.3
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
