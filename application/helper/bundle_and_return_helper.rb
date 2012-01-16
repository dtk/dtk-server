module Ramaze::Helper
  module BundleAndReturnHelper
    def include_css(css_name)
      @css_includes << R8::Config[:base_css_uri] + '/' + css_name + '.css'
    end

#TODO: augment with priority param when necessary
    def include_js(js_name)
      @js_includes << R8::Config[:base_js_uri] + '/' + js_name + '.js'
    end

    def include_js_tpl(js_tpl_name)
      @js_includes << R8::Config[:base_js_uri] + '/cache/' + js_tpl_name
    end

    def add_js_exe(js_content)
      @js_exe_list << js_content
    end

    def run_javascript(js_content)
      @js_exe_list << js_content
    end

    def ret_js_includes()
      includes_ret = @js_includes
      @js_includes = Array.new
      return includes_ret
    end

    def ret_css_includes()
      includes_ret = @css_includes
      @css_includes = Array.new
      return includes_ret
    end

    def ret_js_exe_list()
      exe_list = @js_exe_list
      @js_exe_list = Array.new
      return exe_list
    end
######
  end
end
