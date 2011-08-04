
if(!R8.Topbar2) {

	(function(R8){
	R8.Topbar2 = function() {
		var _id = 'wspace-topbar',
			_node = null,

			_toolbarNodeId = 'wspace-toolbar',
			_toolbarNode = null,

			_toolbars = [],
			_divisions = [],

			_dropdowns = [];

//----------------Dropdown specific---------------------------
		var _viewDropdownId = 'views-dropdown',
			_viewDropdownNode = null,
			_viewDropdownModalNodeId = _viewDropdownId+'-modal',
			_viewDropdownModalNode = null,
			_viewDropdownOpen = false,
			_viewDropdownModalTpl = '<div id="'+_viewDropdownModalNodeId+'" class="dropdown-modal">\
								 <ul id="'+_viewDropdownId+'-list" class="dropdown-list">\
								 	<li id="dock-view" class="dropdown-item">\
										<div class="lft-endcap"></div>\
										<div class="label">\
											<div style="position: relative; margin: 5px 0pt 0pt 5px;">Dock</div>\
										</div>\
										<div class="check-wrapper"><div class="dropdown-check"></div></div>\
										<div class="rt-endcap"></div>\
									</li>\
								 	<li id="cmdbar-view" class="dropdown-item">\
										<div class="lft-endcap"></div>\
										<div class="label">\
											<div style="position: relative; margin: 5px 0pt 0pt 5px;">Cmd Bar</div>\
										</div>\
										<div class="check-wrapper"><div class="dropdown-check"></div></div>\
										<div class="rt-endcap"></div>\
									</li>\
								 </ul>\
							</div>';
//--------------------------------------------------------

		var toolbarDef = {
				tools:[
					{id:'add-users',i18n:'Create User',contentLoader:function(contentNode){
						var route = 'user/edit',
							params = {
								'cfg':{
									'data':'panel_id='+contentNode.get('id')
								}
							};
						R8.Ctrl.call(route,params);
					}},
/*
					{id:'add-environments',i18n:'Add Target',contentLoader:function(contentNode){
						var route = 'datacenter/wspace_edit',
							params = {
								'cfg':{
									'data':'panel_id='+contentNode.get('id')
								}
							};
						R8.Ctrl.call(route,params);
					}},
*/
					{id:'commit',i18n:'Commit',contentLoader:function(contentNode){
//						var route = 'workspace/commit/'+R8.Workspace.get('context_id'),

						var currentView = R8.IDE.get('currentEditorView');
						if (currentView == null) {
							alert('There is nothing to commit');
							return false;
						} else if(currentView.get('type') != 'target') {
							alert('Please open a target to commit its changes');
							return false;
						}
						var viewId = currentView.get('id');
						var targetId = viewId.replace('editor-target-','');
//						var route = 'workspace/commit_ide/'+currentView.get('id'),
						var route = 'workspace/commit_ide/'+targetId,
							params = {
								'cfg':{
									'data':'panel_id='+contentNode.get('id')
								}
							};
						R8.Ctrl.call(route,params);
					}},
/*					{id:'commit-test',i18n:'Test Commit',contentLoader:function(contentNode){
						var route = 'workspace/commit_test/'+R8.Workspace.get('context_id'),
							params = {
								'cfg':{
									'data':'panel_id='+contentNode.get('id')
								}
							};
						R8.Ctrl.call(route,params);
					}},
*/					{id:'create-assembly',i18n:'Create Assembly',contentLoader:function(contentNode){
//						var route = 'workspace/create_assembly/'+R8.Workspace.get('context_id'),
						var route = 'workspace/create_assembly_ide',
							params = {
								'cfg':{
									'data':'panel_id='+contentNode.get('id')
								}
							};
						R8.Ctrl.call(route,params);
					}},
					{id:'create-project',i18n:'Create Project',contentLoader:function(contentNode){
						var route = 'ide/new_project',
							params = {
								'cfg':{
									'data':'panel_id='+contentNode.get('id')
								}
							};
						R8.Ctrl.call(route,params);
					}},
					{id:'create-target',i18n:'Create Target',contentLoader:function(contentNode){
						var route = 'ide/new_target',
							params = {
								'cfg':{
									'data':'panel_id='+contentNode.get('id')
								}
							};
						R8.Ctrl.call(route,params);
					}}
				],
			};

		var dropdownDef = {
			id:'view',
			i18n: 'View',
			type: 'base',
			align: 'left'
		}
		var notificationsDef = {
			id:'notifications',
			i18n: 'Notifications',
			type: 'image',
			align: 'right'
		}
		return {
			init: function(params) {
				_toolbarNodeId = params.toolbarNodeId;

				_node = R8.Utils.Y.one('#'+_id);
				_toolbarNode = R8.Utils.Y.one('#'+_toolbarNodeId);

				_dropdowns[0] = new R8.Dropdown(dropdownDef);
				_toolbarNode.append(_dropdowns[0].render());
				_dropdowns[0].init();

//TODO: revisit to cleanup later
_toolbarNode.append('<div class="divider"></div>');

				_toolbars[0] = new R8.ToolbarGroup2(toolbarDef);
				_toolbarNode.append(_toolbars[0].render());
				_toolbars[0].init();

				var that = this;
				YUI(YUI_config).use("node","event", function(Y) {
//					Y.all('#'+_id+' .toolbar-group').each(function(){
					Y.all('#'+_toolbarNodeId+' .toolbar-group').each(function(){
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
//DEBUG
//TODO: revisit, removing now b/c notifications are moving to console
/*
				var segCfg = {
					'id': 'test',
					'tbarNode': _toolbarNode,
					'align': 'right',
					'plugin': R8.Notifications
				};
				var test = new R8.TbarSegment(segCfg);
				test.init();
*/
			},
			addViewItem: function(def) {
				_dropdowns[0].addItem(def);
			}
		}
	}();

	})(R8)

//--------------------Topbar divisions------------------------------------

	R8.TbarSegment = function(cfg) {
		var _cfg = cfg,
			_id = _cfg.id+'-division',
			_segmentNode = null,
			_node = null,
			_contentNode = null,
			_tbarNode = _cfg.tbarNode,
			_plugin = _cfg.plugin,
			_alignment = _cfg.align,

			_divisionTpl = '<div id="'+_id+'-tbar" style="height: inherit; position: relative;">\
								<div class="divider"></div>\
								<div id="'+_id+'-tbar-content" style="position: relative; float: left; height: 40px;">Hello Foo!!!</div>\
							</div>';

		return {
			init: function() {
				_segmentNode = R8.Utils.Y.Node.create(_divisionTpl);
				_segmentNode.setStyles({'float':_alignment});

				_tbarNode.append(_segmentNode);
				_node = R8.Utils.Y.one('#'+_id+'-tbar');
				_contentNode = R8.Utils.Y.one('#'+_id+'-tbar-content');

				_contentNode.set('innerHTML',_plugin.render());
				_plugin.init({'nodeId':_id+'-tbar'});
			}
		}
	}



//---------------------Dropdown base object--------------------------------

	R8.Dropdown = function(cfg) {
		var _cfg = cfg,
			_id = cfg['id']+'-dropdown',
			_i18n = cfg['i18n'],
			_dropdownNode = null,
//			_tpl = '<div id="'+_id+'" class="dropdown" style="margin-right: 50px; float: left;">\
			_tpl = '<div id="'+_id+'" class="dropdown" style="float: left;">\
							<div style="font-size: 14px; margin-top: 4px; float: left;">'+_i18n+'</div>\
							<div class="arrow"></div>\
						</div>',
			_items = {},
			_numItems = 0,

			_listNodeId = _id+'-list',
			_listNode = null,
			_modalNodeId = _id+'-modal',
			_modalNode = null,
			_dropdownOpen = false,
			_modalTpl = '<div id="'+_modalNodeId+'" class="dropdown-modal">\
								 <ul id="'+_id+'-list" class="dropdown-list">\
								 </ul>\
							</div>';
/*
								 	<li id="dock-view" class="dropdown-item">\
										<div class="lft-endcap"></div>\
										<div class="label">\
											<div style="position: relative; margin: 5px 0pt 0pt 5px;">Dock</div>\
										</div>\
										<div class="check-wrapper"><div class="dropdown-check"></div></div>\
										<div class="rt-endcap"></div>\
									</li>\
								 	<li id="cmdbar-view" class="dropdown-item">\
										<div class="lft-endcap"></div>\
										<div class="label">\
											<div style="position: relative; margin: 5px 0pt 0pt 5px;">Cmd Bar</div>\
										</div>\
										<div class="check-wrapper"><div class="dropdown-check"></div></div>\
										<div class="rt-endcap"></div>\
									</li>\

 */
		return {
			init: function() {
				//setup modal and base events to hide/show
				_dropdownNode = R8.Utils.Y.one('#'+_id);
				_dropdownNode.on('click',function(e){
					this.toggleDropdown();
					e.stopImmediatePropagation();
				},this);
				_dropdownNode.on('mouseenter',function(e){
					e.currentTarget.addClass('mover');
				},this);
				_dropdownNode.on('mouseleave',function(e){
					e.currentTarget.removeClass('mover');
				},this);

				R8.Utils.Y.one('#page-container').append(_modalTpl);

				_modalNode = R8.Utils.Y.one('#'+_modalNodeId);
				_modalNode.on('click',function(e){
					e.stopImmediatePropagation();
				},this);

				var topbarNodeId = R8.IDE.get('topbarNodeId');
				var mTop = R8.Utils.Y.one('#'+topbarNodeId).get('region').bottom,
					mLeft = _dropdownNode.get('region').left-3;

				_modalNode.setStyles({'top':mTop,'left':mLeft});

				_listNode = R8.Utils.Y.one('#'+_listNodeId);

				R8.Utils.Y.one('#page-container').on('click',function(e){
					if(this.dropdownOpen()) this.toggleDropdown();
				},this);

				//setup base events for dropdown list items
				var ddItemMenter = R8.Utils.Y.delegate('mouseenter',function(e){
					if(e.currentTarget.getAttribute('data-active') != 'true') {
						e.currentTarget.addClass('visible');
					}
				},'#'+_id+'-list','.dropdown-item');
				var ddItemMeave = R8.Utils.Y.delegate('mouseleave',function(e){
					if(e.currentTarget.getAttribute('data-active') != 'true') {
						e.currentTarget.removeClass('visible');
					}
				},'#'+_id+'-list','.dropdown-item');

				var ddItemClick = R8.Utils.Y.delegate('click',function(e){
					if(e.currentTarget.getAttribute('data-active') == 'true') {
						e.currentTarget.setAttribute('data-active','false');
					} else {
						e.currentTarget.addClass('visible');
						e.currentTarget.setAttribute('data-active','true');
					}
					this.fireClickCallback(e.currentTarget.get('id'));
				},'#'+_id+'-list','.dropdown-item',this);
			},
			render: function() {
				return _tpl;
			},
			fireClickCallback: function(itemId) {
				var id = itemId.replace('-view','');
				_items[id].clickCallback();
			},
			addItem: function(itemDef) {
				var id = itemDef.id,
					i18n = itemDef.i18n,
					startVisibleStatus = (typeof(itemDef.visible) !='undefined' && itemDef.visible==true) ? 'visible' : '',
					visibleDataAttr = (startVisibleStatus == 'visible') ? 'data-active="true"':'',
					itemTpl = '<li id="'+id+'-view" class="dropdown-item '+startVisibleStatus+'" '+visibleDataAttr+'>\
										<div class="lft-endcap"></div>\
										<div class="label">\
											<div style="position: relative; margin: 5px 0pt 0pt 5px;">'+i18n+'</div>\
										</div>\
										<div class="check-wrapper"><div class="dropdown-check"></div></div>\
										<div class="rt-endcap"></div>\
									</li>';

				_items[id] = itemDef;
				_numItems = _numItems+1;
				var newHeight = _numItems*35;
				_modalNode.setStyle('height',newHeight);
				_listNode.setStyle('height',newHeight);
				_listNode.append(itemTpl);
			},

			removeItem: function(itemId) {
				
			},

			dropdownOpen: function() {
				return _dropdownOpen;
			},
			toggleDropdown: function() {
				if(_dropdownOpen == true) {
					_dropdownNode.removeClass('active');
					_modalNode.setStyle('display','none');
					_dropdownOpen = false;
				} else {
					_dropdownNode.addClass('active');
					_modalNode.setStyle('display','block');
					_dropdownOpen = true;
				}
			}
		}
	}


}