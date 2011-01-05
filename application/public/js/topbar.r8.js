
if(!R8.Topbar) {

	(function(R8){
	R8.Topbar = function() {
		var _id = 'wspace-topbar',
			_node = null,
			_toolbarNodeId = 'wspace-toolbar',
			_toolbarNode = null,
			_toolbars = [];

		var groupDef = {
				tools:[
					{id:'add-users',i18n:'Create User'}
				],
			};

		return {
			init: function() {
				_node = R8.Utils.Y.one('#'+_id);
				_toolbarNode = R8.Utils.Y.one('#'+_toolbarNodeId);

				_toolbars[0] = new R8.ToolbarGroup(groupDef);
				_toolbarNode.append(_toolbars[0].render());
				_toolbars[0].init();

				var that = this;
				YUI(YUI_config).use("node","event", function(Y) {
					Y.all('#'+_id+' .toolbar-group').each(function(){
						var groupId = this.get('id'),
							tbarGroupNode = document.getElementById(groupId);
			
						var itemMouseOver = R8.Utils.Y.delegate('mouseenter',function(e){
							e.currentTarget.addClass('active');
						},tbarGroupNode,'.tool-item');

						var itemMouseDown = R8.Utils.Y.delegate('mousedown',function(e){
							e.currentTarget.addClass('mdown');
						},tbarGroupNode,'.tool-item');
						var itemMouseDown = R8.Utils.Y.delegate('mouseup',function(e){
							e.currentTarget.removeClass('mdown');
						},tbarGroupNode,'.tool-item');

						var itemMouseOut = R8.Utils.Y.delegate('mouseleave',function(e){
							e.currentTarget.removeClass('active');
						},tbarGroupNode,'.tool-item');
					});

				});

			}
		}		
	}();

	})(R8)
}
