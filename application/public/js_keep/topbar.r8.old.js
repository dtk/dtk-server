
if(!R8.Topbar) {

	(function(R8){
	R8.Topbar = function() {
		var _id = 'wspace-topbar',
			_node = null,

			_toolbarNodeId = 'wspace-toolbar',
			_toolbarNode = null,
			_toolbars = [];

//----------------Dropdown specific---------------------------
		var _viewDropdownId = 'views-dropdown',
			_viewDropdownNode = null,
			_viewDropdownModalNodeId = _viewDropdownId+'-modal',
			_viewDropdownModalNode = null,
			_viewDropdownOpen = false,
			_viewDropdownModalTpl = '<div id="'+_viewDropdownModalNodeId+'" class="dropdown-modal">\
								<ul \
							</div>';
//--------------------------------------------------------

		var groupDef = {
				tools:[
					{id:'add-users',i18n:'Create User',contentLoader:function(){
						var route = 'user/edit',
							params = {
								'cfg':{
									'data':'panel_id='+contentNode.get('id')
								}
							};
						R8.Ctrl.call(route,params);
					}},
					{id:'datacenters',i18n:'Datacenters',contentLoader:function(contentNode){
						var route = 'user/edit',
							params = {
								'cfg':{
									'data':'panel_id='+contentNode.get('id')
								}
							};
						R8.Ctrl.call(route,params);
					}}
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

				this.setupViewTool();
			},

//-------------------DROPDOWN STUFF HERE FOR NOW UNTIL MORE WORK DONE------------------------------

			setupViewTool: function() {
				var that=this;
				_viewDropdownNode = R8.Utils.Y.one('#'+_viewDropdownId);
				_viewDropdownNode.on('click',function(e){
					that.toggleViewDropdown();
				});
				R8.Utils.Y.one('#page-container').append(_viewDropdownModalTpl);
				_viewDropdownModalNode = R8.Utils.Y.one('#'+_viewDropdownModalNodeId);
				var mTop = R8.Utils.Y.one('#wspace-topbar').get('region').bottom,
					mLeft = _viewDropdownNode.get('region').left-3;

				_viewDropdownModalNode.setStyles({'top':mTop,'left':mLeft});
			},
			toggleViewDropdown: function() {
				if(_viewDropdownOpen == true) {
					_viewDropdownNode.removeClass('open');
					_viewDropdownModalNode.setStyle('display','none');
					_viewDropdownOpen = false;
				} else {
					_viewDropdownNode.addClass('open');
					_viewDropdownModalNode.setStyle('display','block');
					_viewDropdownOpen = true;
				}
			}
		}		
	}();

	})(R8)
}
