

#need to rework/architect as needed, this is from first test pass

module R8
  Config = Hash.new
end

#these are used in view.r8.rb
R8::Config[:appRootPath] = "/root/Reactor8/demo-tpl-handling/"
prefix = R8::Config[:appRootPath] + "formtests/"
R8::Config[:tplCacheRoot] = prefix + 'cache/'
#R8::Config[:devMode] = false
R8::Config[:devMode] = true

#these are used in template.r8.rb
R8::Config[:js_file_write_path] = "/root/Reactor8/top/project1/public/js"
R8::Config[:rtpl_compile_dir] = prefix + 'rtplCompile'
R8::Config[:rtpl_cache_dir] = prefix + 'rtplCache'
R8::Config[:views_root_dir] = prefix + 'views'
R8::Config[:js_templating_on] = true

