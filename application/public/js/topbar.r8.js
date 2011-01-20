
if(!R8.Topbar) {

	(function(R8){
	R8.Topbar = function() {
		var _id = 'wspace-topbar',
			_node = null,

			_toolbarNodeId = 'wspace-toolbar',
			_toolbarNode = null,
			_toolbars = [],

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

		var groupDef = {
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
					{id:'datacenters',i18n:'Datacenters',contentLoader:function(contentNode){
						var route = 'user/edit',
							params = {
								'cfg':{
									'data':'panel_id='+contentNode.get('id')
								}
							};
						R8.Ctrl.call(route,params);
					}},
					{id:'commit',i18n:'Commit',contentLoader:function(contentNode){
						var route = 'workspace/commit/'+R8.Workspace.get('context_id'),
							params = {
								'cfg':{
									'data':'panel_id='+contentNode.get('id')
								}
							};
						R8.Ctrl.call(route,params);
					}},
					{id:'commit-test',i18n:'Test Commit',contentLoader:function(contentNode){
						var route = 'workspace/commit_test/'+R8.Workspace.get('context_id'),
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
			type: 'base'
		}

		return {
			init: function() {
				_node = R8.Utils.Y.one('#'+_id);
				_toolbarNode = R8.Utils.Y.one('#'+_toolbarNodeId);

				_dropdowns[0] = new R8.Dropdown(dropdownDef);
				_toolbarNode.append(_dropdowns[0].render());
				_dropdowns[0].init();

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
			},
			addViewItem: function(def) {
				_dropdowns[0].addItem(def);
			}
		}		
	}();

	})(R8)

//---------------------Dropdown base object--------------------------------

	R8.Dropdown = function(cfg) {
		var _cfg = cfg,
			_id = cfg['id']+'-dropdown',
			_i18n = cfg['i18n'],
			_dropdownNode = null,
			_tpl = '<div id="'+_id+'" class="dropdown" style="margin-right: 50px; float: left;">\
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

				var mTop = R8.Utils.Y.one('#wspace-topbar').get('region').bottom,
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
					_dropdownNode.removeClass('open');
					_modalNode.setStyle('display','none');
					_dropdownOpen = false;
				} else {
					_dropdownNode.addClass('open');
					_modalNode.setStyle('display','block');
					_dropdownOpen = true;
				}
			}
		}
	}


}