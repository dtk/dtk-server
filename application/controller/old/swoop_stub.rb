#all this is a hack for demo integration

#lib = "/root/Reactor8/demo-tpl-handling/formtests/" 

#$: << lib unless $:.include?(lib)
#require 'config.r8.rb'


  module R8View
    Views = {}
  end
  module R8
    I18N = {}
  end
#  require 'i18n/component/en.us.rb' #TBD: should be conditionally loaded


module XYZ
  class MainController < Controller

    #TBD: testing swoop
    def swoop
      INDEX_HTML
    end
    def actset__main()
      http_opts = ret_parsed_query_string()
      c = ret_session_context_id()

      #print "request is #{request.inspect}\n"
      print "query string is #{http_opts.inspect}\n"
      #stubbed vars
        object_name = :component
        action_name = http_opts[:action] == :display ? :display : :list
        js_action_ref = "list_components"

        uri = "/library/saved/component/bundle/component"
        href_prefix = "http://" + http_host() + "/list"
        id_handle = http_opts[:id] ? IDHandle[:c => c,:guid => http_opts[:id]] : IDHandle[:c => c,:uri => uri]

      #TBD: whether haev call for laoding resulst and one for returning results
      r= ActionSet::Singleton.process(object_name,action_name,js_action_ref,id_handle,href_prefix,http_opts)
      r
    end


 #TBD: put in template file
 INDEX_HTML = %q{
<html>
<head id="appHeadElem">

<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.7.0/build/reset/reset.css" />
<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.7.0/build/fonts/fonts.css" />

<!--//TODO: revisit to variablize the path of the founcation css-->
<link rel="stylesheet" type="text/css" href="css/default.foundation.css" />

<!--//TODO: revisit to variablize appFoundationTitle-->
<title>Welcome to Swoop Net</title>
</head>

<body id="pageBody" class="yui-skin-sam" onload="R8.ctrl.loadApp('');">
<div id="appWrapper">
	<div id="appContainer">
		<div id="appHeaderPanel">
			<div id="appLogo"></div>
			<div id="userAccountContent"></div>
		</div>
		
		<div id="appMainPanel">
			<div id="leftColPanel">&nbsp;</div>
			<div id="appBodyPanel">&nbsp;</div>
		</div>

		<div id="appFooterPanel">
		&nbsp;
		</div>

		<div id="scriptContainer">

		<script src="http://yui.yahooapis.com/2.7.0/build/yahoo/yahoo-min.js"></script>
		<script src="http://yui.yahooapis.com/2.7.0/build/event/event-min.js"></script>
		<script src="http://yui.yahooapis.com/2.7.0/build/dom/dom-min.js"></script>
		<script src="http://yui.yahooapis.com/2.7.0/build/connection/connection-min.js"></script>
		<script src="http://yui.yahooapis.com/2.7.0/build/animation/animation-min.js"></script>
<!--
		<script type="text/javascript" src="{%=jsIncludePath%}ctrl.r8.js"></script>
		<script type="text/javascript" src="{%=jsIncludePath%}utils.r8.js"></script>
		<script type="text/javascript" src="{%=jsIncludePath%}fields.r8.js"></script>
-->
		<script type="text/javascript" src="js/ctrl.r8.js"></script>
		<script type="text/javascript" src="js/utils.r8.js"></script>
		<script type="text/javascript" src="js/fields.r8.js"></script>
		<script type="text/javascript">
				//var loadAppArgs = {%=loadAppArgs%};
		</script>
		</div>
	</div>
</div>
</body>
</html>

}

end
end
