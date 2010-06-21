<html>
<head>

<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/combo?3.1.0/build/cssreset/reset-min.css&3.1.0/build/cssfonts/fonts-min.css">

<!--//TODO: revisit to variablize the path of the founcation css-->
<link rel="stylesheet" type="text/css" href="<%= @public_css_root %>/workspace.css" />
<link rel="stylesheet" type="text/css" href="<%= @public_css_root %>/basic-component.css" />


<!-- JS 
<script type="text/javascript" src="http://yui.yahooapis.com/combo?3.1.0/build/yui/yui-min.js&3.1.0/build/oop/oop-min.js&3.1.0/build/dom/dom-min.js&3.1.0/build/event-custom/event-custom-min.js&3.1.0/build/event/event-min.js&3.1.0/build/pluginhost/pluginhost-min.js&3.1.0/build/node/node-min.js&3.1.0/build/querystring/querystring-stringify-simple-min.js&3.1.0/build/queue-promote/queue-promote-min.js&3.1.0/build/datatype/datatype-xml-min.js&3.1.0/build/io/io-min.js&3.1.0/build/attribute/attribute-min.js&3.1.0/build/base/base-min.js&3.1.0/build/dd/dd-min.js"></script>
-->

<!-- JS -->
<script type="text/javascript" src="http://yui.yahooapis.com/combo?3.1.0/build/yui/yui-min.js&3.1.0/build/oop/oop-min.js&3.1.0/build/event-custom/event-custom-min.js&3.1.0/build/dom/dom-min.js&3.1.0/build/event/event-min.js&3.1.0/build/pluginhost/pluginhost-min.js&3.1.0/build/node/node-min.js&3.1.0/build/attribute/attribute-base-min.js&3.1.0/build/base/base-min.js&3.1.0/build/anim/anim-min.js&3.1.0/build/dd/dd-min.js&3.1.0/build/querystring/querystring-stringify-simple-min.js&3.1.0/build/queue-promote/queue-promote-min.js&3.1.0/build/datatype/datatype-xml-min.js&3.1.0/build/io/io-min.js"></script>
<!-- JS -->
<script type="text/javascript" src="<%= @public_js_root %>/demoData.r8.js"></script>
<script type="text/javascript" src="<%= @public_js_root %>/demoData2.r8.js"></script>

<!--
<script type="text/javascript" src="http://yui.yahooapis.com/combo?3.0.0/build/yui/yui-min.js&3.0.0/build/loader/loader-min.js"></script>
-->

<!--Temp Usage of jQuery for eval purposes -->
<script src="http://code.jquery.com/jquery-latest.js"></script>

<script type="text/javascript" src="<%= @public_js_root %>/r8.js"></script>
<script type="text/javascript" src="<%= @public_js_root %>/ctrl.r8.js"></script>
<script type="text/javascript" src="<%= @public_js_root %>/canvas.r8.js"></script>
<script type="text/javascript" src="<%= @public_js_root %>/templating.r8.js"></script>
<script type="text/javascript" src="<%= @public_js_root %>/render_basic_component.js"></script>
<script type="text/javascript" src="<%= @public_js_root %>/render_tbar_component.js"></script>
<script type="text/javascript" src="<%= @public_js_root %>/workspace.r8.js"></script>
<script type="text/javascript" src="<%= @public_js_root %>/utils.r8.js"></script>
<script type="text/javascript" src="<%= @public_js_root %>/component.r8.js"></script>
<script type="text/javascript" src="<%= @public_js_root %>/maintoolbar.r8.js"></script>

<script type="text/javascript">
</script>

</head>

	<body style="background: repeat-x url(<%= @public_images_root %>/workspace/page-bg.jpg) scroll left top #4E87A7;" onload="R8.ctrl.init(); R8.Workspace.loadWorkspace();">
	<div style=" width: 1200px; margin: 0 auto 0 auto;">
		<div id="toolbar">
			<a href="javascript:R8.MainToolbar.toggleSlider();">Toggle</a>
			<div class="tbar_search"">
				<form id="tbar_search_form" onsubmit="R8.MainToolbar.search(); return false;">
					<input onfocus="if(this.value =='Search') {this.value='';}" type="text" value="Search" id="sq" name="sq" title="Enter Search Term"/>
					<input class="tbar_search_submit" onclick="R8.MainToolbar.search();" type="button" title="Search" value=""/>
				</form>
			</div>
		</div>
		<div id="sliderbar">
			<div class="slider-top"></div>
			<div id="sliderwrapper">
				<div id="lbutton"></div>
				<div id="slidecontainer">
					<div id="slider"></div>
				</div>
				<div id="rbutton"></div>
			</div>
			<div class="slider-btm"></div>
		</div>
		<div id="wspaceContainer">
			<div id="mainWorkspace" class="mainWorkspace">
				<div id="wspaceHeader">
					<div id="wsh-l-corner"></div>
					<div id="wsh-center"></div>
					<div id="wsh-r-corner"></div>
				</div>
			</div>
		</div>
	</div>
	</body>
</html>
