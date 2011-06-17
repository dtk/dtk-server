
if(!R8.Dock2) {

	(function(R8){

	R8.Dock2 = function() {
		var _nodeId = 'wspace-dock',
			_node = null,
			_overlay = null,
			_headerNode = null,
			_bodyNode = null,
			_footerNode = null,

			_dockAlignNodeId = '',

			_display = 'none',
			_width = 225,
			_height = 25,
			_right = '0',
			_top = '0',

			_panels = [],
			_toggleCache = {},

			_itemFocusList = {},

			testMeta = {
				panels:[{
					items:[
						{
							id:'info',i18n:'Info',
							modal: {
									fixed_size: false,
									min_height: 150,
									min_width: 150,
									max_height: 700,
									max_width: 700,
									width: 200,
									height: 200
								}
						},
						{
							id:'users',i18n:'Users',
							modal: {
									fixed_size: false,
									min_height: 150,
									min_width: 150,
									max_height: 300,
									max_width: 500,
									width: 260,
									height: 260
								}
						},
						{id:'applications',i18n:'Applications',
							modal: {
									fixed_size: false,
									min_height: 150,
									min_width: 150,
									max_height: 300,
									max_width: 500,
									width: 260,
									height: 260
								}
						},
						{id:'service-checks',i18n:'Service Checks',
							modal: {
									fixed_size: false,
									min_height: 150,
									min_width: 150,
									max_height: 300,
									max_width: 500,
									width: 260,
									height: 260
								}
						}
					],
				}]
			};
		return {
			init: function(alignNodeId) {
				_dockAlignNodeId = alignNodeId;

				_node = R8.Utils.Y.one('#'+_nodeId);
				_headerNode = R8.Utils.Y.one('#'+_nodeId+'-header');
				_bodyNode = R8.Utils.Y.one('#'+_nodeId+'-body');
				_footerNode = R8.Utils.Y.one('#'+_nodeId+'-footer');

				for(var i in testMeta.panels) {
					testMeta.panels[i]['id'] = 'panel-'+i;
					_panels[i] = new R8.Dock2.panel(testMeta.panels[i]);
					_bodyNode.append(_panels[i].render());
					_panels[i].init();
					_height = _height+_panels[i].get('height');
				}

				var that = this;
				YUI(YUI_config).use("overlay","node","event", function(Y) {
				    _overlay = new Y.Overlay({
				        srcNode:'#'+_nodeId,
				        width:_width+'px',
				        height:_height+'px',
						align: {
							node: '#'+_dockAlignNodeId,
							points: ['tr','tr']
						}
				    });
				    _overlay.render();

					var topbarNode = Y.one('#wspace-dock-top-bar');
					topbarNode.on('click',function(e){
						if(_node.hasClass('collapsed')) {
							_overlay.set('width','225px');
							_node.removeClass('collapsed');
							_overlay.set('align',{node: "#"+_dockAlignNodeId,points: ["tr", "tr"]});
						} else {
							_overlay.set('width','45px');
							_node.addClass('collapsed');
							_overlay.set('align',{node: "#"+_dockAlignNodeId,points: ["tr", "tr"]});
						}

						if(that.hasOpenModal()) {
							that.realignOpenModals();
						}
					});
//DEBUG
//appears this isnt needed
//					_node.setStyles({'display':'block'});

					Y.all('#'+_nodeId+' .panel-list').each(function(){
						var groupId = this.get('id'),
							panelGroupNode = document.getElementById(groupId);

						var itemMouseOver = R8.Utils.Y.delegate('mouseenter',function(e){
							e.currentTarget.addClass('active');
						},panelGroupNode,'.panel-item');

						var itemMouseOut = R8.Utils.Y.delegate('mouseleave',function(e){
							if(!e.currentTarget.hasClass('open'))
								e.currentTarget.removeClass('active');
						},panelGroupNode,'.panel-item');

//						var itemClick = R8.Utils.Y.delegate('click',function(e){
//alert(e.currentTarget.get('id'));
//						},panelGroupNode,'.panel-item');

					});
//DEBUG
//hiding the dock by default for demo, change after implementing user settings/memory
					that.hide();
				});
				R8.Topbar2.addViewItem({
					id: 'dock',
					i18n: 'Dock',
					visible: false,
					clickCallback: this.toggleDock
				});
			},

			get: function(item) {
				switch(item) {
					case "itemFocusList":
						return _itemFocusList;
						break;
				}
			},

			hasOpenModal: function() {
				for(var i in _panels) {
					var items = _panels[i].get('items');
					for(var j in items) {
						if(items[j].opened()) return true;
					}
				}
				return false;
			},

			realignOpenModals: function() {
				for(var i in _panels) {
					var items = _panels[i].get('items');
					for(var j in items) {
						if(items[j].opened()) items[j].realignModal();
					}
				}
			},

			render: function(params) {
				_display = (!params['display']) ? 'none' : params['display'];
				_top = (!params['top']) ? '0' : params['top'];
				_right = (!params['right']) ? '0' : params['right'];

//				var dockTpl = '<div id="wspace-dock" class="yui3-overlay-loading" style="position:absolute; display: '+_display+'; z-index: 50;">\
				var dockTpl = '<div id="wspace-dock" class="yui3-overlay-loading" style="position:absolute; display: '+_display+'; z-index: 50;">\
						    <div id="wspace-dock-header" class="yui3-widget-hd">\
								<div class="corner tl"></div>\
								<div class="top-bottom-body"></div>\
								<div class="corner tr"></div>\
								<div id="wspace-dock-top-bar" class="expand-collapse-bar">\
									<div class="expand-collapse-arrows"></div>\
								</div>\
						    </div>\
						    <div id="wspace-dock-body" class="yui3-widget-bd">\
						    </div>\
						    <div id="wspace-dock-footer" class="yui3-widget-ft">\
								<div class="corner bl"></div>\
								<div class="top-bottom-body"></div>\
								<div class="corner br"></div>\
							</div>\
						</div>';

				return dockTpl;
			},

			focusChange: function(focusDetails) {
				_itemFocusList = focusDetails;

				if(this.hasOpenModal()) {
					this.updateOpenModals();
				}
			},

			updateOpenModals: function() {
				for(var i in _panels) {
					var items = _panels[i].get('items');
					for(var j in items) {
						if(items[j].opened()) items[j].refreshContent();
					}
				}
			},

			init2: function() {
//TODO: temp until implmenting first panel setup
//				_panels.push('temp');

				YUI().use('anim', function(Y){
					_topbarAnim = new Y.Anim({
						node: '#'+_topbarNodeId,
						duration: 0.2
					});
					_bodyAnim = new Y.Anim({
						node: '#'+_bodyNodeId,
						duration: 0.2
					});
				});

				var that=this;

				R8.Utils.Y.on('available', _setTopbarNode, '#'+_topbarNodeId,this);
				R8.Utils.Y.on('available', _setBodyNode, '#'+_bodyNodeId,this);

//				_topbarNode = R8.Utils.Y.one('#'+_topbarNodeId);
//				_bodyNode = R8.Utils.Y.one('#'+_bodyNodeId);
//console.log('testing....');
//console.log(_bodyNode)
/*
				R8.Utils.Y.delegate('click',function(e){
						that.pushDockPanel({
							'title':'Cloudera C3',
							'topbarNode':_topbarNode,
							'bodyNode':_bodyNode,
							'indexPos':_panels.length
						});
//console.log(e.currentTarget);
				},'#wspace-dock-body-01','.wspace-dock-list-item',this);
*/

				R8.Utils.Y.delegate('click',function(e){
					that.panelSlideRight();
				},'#wspace-dock-topbar','.back-btn',this);

				//Panel Items in Minimized List
				R8.Utils.Y.delegate('click',function(e) {
					var activeItems = R8.Workspace.getSelectedItems();
					var route = '';
					var count=0;

					for(itemId in activeItems) {
						count++;
					}
					if(count == 1) {
						for(itemId in activeItems) {
							if(activeItems[itemId]['model'] == 'node') {
								route = 'node/get_components/'+itemId;
							}
						}
						var that = this;
						var maximize = function(){
							that.maximize();
						}
						setTimeout(maximize,100);
						R8.Dock2.loadDockPanel(route);
					}

				},'#wspace-dock-panel-list','.panel-item',this);
				R8.Utils.Y.delegate('mouseenter',function(e) {
					var itemNode = R8.Utils.Y.one('#'+e.currentTarget.get('id'));
					itemNode.addClass('active');
				},'#wspace-dock-panel-list','.panel-item',this);
				R8.Utils.Y.delegate('mouseleave',function(e) {
					var itemNode = R8.Utils.Y.one('#'+e.currentTarget.get('id'));
					itemNode.removeClass('active');
				},'#wspace-dock-panel-list','.panel-item',this);
			},
/*
			panelSlideLeft: function() {
				if (_topbarAnimEvent != null) {
					_topbarAnimEvent.detach();
					_topbarAnimEvent = null;
				}

				_topbarAnim.set('to', {
					xy: [_topbarNode.getX()-250, _topbarNode.getY()]
				});
				_bodyAnim.set('to', {
					xy: [_bodyNode.getX()-250, _bodyNode.getY()]
				});


//				_topbarAnim.on('end',function(e){
//				});
//				_bodyAnim.on('end',function(e){
//				});

				_topbarAnim.run();
				_bodyAnim.run();
			},

			panelSlideRight: function() {
				_topbarAnim.set('to', {
					xy: [_topbarNode.getX()+250, _topbarNode.getY()]
				});
				_bodyAnim.set('to', {
					xy: [_bodyNode.getX()+250, _bodyNode.getY()]
				});

				_topbarAnim.run();
				_bodyAnim.run();

				var that=this;
				if(_topbarAnimEvent == null) {
					_topbarAnimEvent = _topbarAnim.on('end', function(e){
						that.popDockPanel();
					});
				}
			},
*/
			loadDockPanel: function(route) {
				var params = {
					'cfg': {
//						'data':'_rndm='+R8.Utils.Y.guid(),
						'method': 'GET'
					},
//					'callbacks': {
//						'io:success':this.getPanelCfg
//					}
				};
				R8.Ctrl.call(route,params);
			},

//			updatePage: function(ioId, responseObj) {
//				eval("R8.Ctrl.callResults[ioId]['response'] =" + responseObj.responseText);
//				var response = R8.Ctrl.callResults[ioId]['response'];

			pushDockPanel2: function(dockId,panelCfg,tplName) {
				var numItems = panelCfg['item_list'].length,
					scroll = (numItems > 10) ? true : false;

				panelCfg['bodyContent'] = R8.Rtpl[tplName]({'item_list':panelCfg['item_list']});
				panelCfg['topbarNode'] = _topbarNode;
				panelCfg['bodyNode'] = _bodyNode;
				panelCfg['indexPos'] = _panels.length;
				panelCfg['backBtn'] = (_panels.length >= 1) ? true : false;
				this.pushDockPanel(panelCfg,scroll);
			},

			pushDockPanel: function(panelCfg,scroll) {
				var newWidth = _dockWidth*(_panels.length+1);
				_topbarNode.setStyle('width',newWidth+'px');
				_bodyNode.setStyle('width',newWidth+'px');

				_panels.push(new R8.Dock2.panel(panelCfg));
				_panels[_panels.length-1].init(scroll);
				if(_panels.length > 1) this.panelSlideLeft();
			},

			popDockPanel: function() {
				_panels[_panels.length-1].destroy();
				delete(_panels.pop());

				var newWidth = _dockWidth*(_panels.length);
				_topbarNode.setStyle('width',newWidth+'px');
				_bodyNode.setStyle('width',newWidth+'px');
			},

			toggleDock: function() {
				if(_node == null) _node = R8.Utils.Y.one('#'+_nodeId);

				if (_node.get('parentNode').getStyle('display') == 'block') {
					R8.Dock2.hide();
					R8.Dock2.closeAllPanels();
				} else {
					R8.Dock2.show();
				}
			},
			show: function() {
				if(_node == null) _node = R8.Utils.Y.one('#'+_nodeId);

				_node.get('parentNode').setStyle('display','block');
				for(var p in _toggleCache) {
					var items = _panels[p].get('items');
					for(var i in _toggleCache[p]) {
						items[_toggleCache[p][i]].open();
					}
				}
				_toggleCache = {};
			},
			hide: function() {
				if(_node == null) _node = R8.Utils.Y.one('#'+_nodeId);
				_node.get('parentNode').setStyle('display','none');
			},
			closeAllPanels: function() {
				for(var i in _panels) {
					var items = _panels[i].get('items');
					for(var j in items) {
						if(items[j].opened()) {
							_toggleCache[i] = [j];
							items[j].close();
						}
					}
				}
			},

			toggleMinMax: function() {
				if(_node == null) _node = R8.Utils.Y.one('#'+_nodeId);

				if(_node.hasClass('minimized')) {
					_node.removeClass('minimized');
					_node.addClass('maximized');
				} else {
					_node.removeClass('maximized');
					_node.addClass('minimized');
				}
			},
			maximize: function() {
				if(_node == null) _node = R8.Utils.Y.one('#'+_nodeId);

				_node.removeClass('minimized');
				_node.addClass('maximized');
			},
			minimize: function() {
				if(_node == null) _node = R8.Utils.Y.one('#'+_nodeId);

				_node.removeClass('maximized');
				_node.addClass('minimized');
			},

			panelSubmit: function(formId) {
				var form = document.getElementById(formId),
					route = form.route.value,
					cfg = {
						form: {
							id: formId,
							useDisabled: true
						}
					};
				var params = {
					'cfg': cfg
				}
				R8.Ctrl.call(route,'',params);
			},

			saveAttributes: function(formId) {
				var form = document.getElementById(formId),
					route = form.save_route.value,
					cfg = {
						form: {
							id: formId,
							useDisabled: true
						}
					};
				var params = {
					'cfg':cfg
				}
				R8.Ctrl.call(route,params);
			}
		}
	}();

	})(R8)

//-------DOCK PANEL---------------

	R8.Dock2.panel = function(cfg) {
		var _cfg = cfg,
			_id = cfg['id'],
			_listNode = null,
			_height = null,
			_tpl = '<div id="'+_id+'" class="panel-group">\
						<div class="header"></div>\
							<ul id="'+_id+'-list" class="panel-list">\
							</ul>\
						</div>\
				    </div>',
			_events = {},
			_items = {},
			_numItems = 0;

		return {
			init: function() {
				_listNode = R8.Utils.Y.one('#'+_id+'-list');

				for(var i in _cfg['items']) {
					var itemId = _cfg['items'][i]['id'];
					_cfg['items'][i]['list_node'] = _listNode;
					_items[itemId] = new R8.Dock2.panelItem(_cfg['items'][i]);
					_listNode.append(_items[itemId].render());
					_items[itemId].init();
					_numItems++;
				}

				_height = 8 + _numItems*35;

				_events['itemClick'] = R8.Utils.Y.delegate('click',function(e){
					var itemNodeId = e.currentTarget.get('id');
					var itemId = itemNodeId.replace('-panel-item','');

					for(var item in _items) {
						if(item == itemId) continue;
						else {
							_items[item].close();
							_items[item].get('node').removeClass('active');
						}
					}
					if(_items[itemId].opened()) _items[itemId].close();
					else _items[itemId].open();

				},_listNode,'.panel-item');

			},
			render: function() {
				return _tpl;
			},

			get: function(property) {
				switch(property) {
					case "height":
						return _height;
						break;
					case "items":
						return _items;
						break;
				}
			},

			destroy: function() {
/*
				var bdyChildren = _bodyNode.get('children'),
					tpbarChildren = _topbarNode.get('children');

				bdyChildren.item(_indexPos).purge(true);
				bdyChildren.item(_indexPos).remove();
				tpbarChildren.item(_indexPos).purge(true);
				tpbarChildren.item(_indexPos).remove();
*/
			}
		}
	}

	R8.Dock2.panelItem = function(cfg) {
		var _cfg = cfg,
			_id = cfg['id'],
			_pluginName = _id.replace('-','_')+'Plugin',
			_panelPlugin = null,
			_listNode = cfg['list_node'],
			_node = null,
			_overlay = null,
			_opened = false,
			_i18n = cfg['i18n'],
			_tpl = '<li id="'+_id+'-panel-item" class="panel-item">\
						<div class="lft-endcap"></div>\
						<div class="panel-btn-bg">\
							<div class="panel-btn '+_id+'"></div>\
						</div>\
						<div class="label">\
							<div style="position: relative; margin: 5px 0 0 15px;">'+_i18n+'</div>\
						</div>\
						<div class="rt-endcap"></div>\
					</li>',

			_resizeMouseDown = false,
			_widthResizer = null,
			_heightResizer = null,
			_diagResizer = null,

			_modalCfg = cfg['modal'],
			_modalNode = null,
			_modalContentNode = null,
			_modalHeaderNode = null,
			_modalHeight = 260,
			_modalWidth = 260,
			_modalTpl = '<div id="'+_id+'-modal" class="yui3-overlay-loading panel-modal">\
							<div class="yui3-widget-hd">\
							</div>\
							<div class="yui3-widget-bd">\
							adsffffffffffff</div>\
							<div class="yui3-widget-ft">\
							</div>\
						</div>';

				var dockTpl = '<div id="'+_id+'-modal" class="yui3-overlay-loading panel-modal" style="position:absolute; display: block; z-index: 51;">\
						    <div id="'+_id+'-modal-header" class="yui3-widget-hd">\
								<div class="corner tl"></div>\
								<div class="top-bottom-body width-resizer"></div>\
								<div class="corner tr"></div>\
								<div id="'+_id+'-modal-top-bar" class="expand-collapse-bar">\
									<div class="expand-collapse-arrows"></div>\
								</div>\
						    </div>\
						    <div id="'+_id+'-modal-body" class="yui3-widget-bd">\
								<div id="'+_id+'-modal-resize-width" class="width-resize-drag"></div>\
								<div id="'+_id+'-modal-content" class="width-resizer" style="height: 100%; width: 250px; background-color: #EDEDED; overflow-y: scroll;">Panel for <b>'+_i18n+'</b></div>\
						    </div>\
						    <div id="'+_id+'-modal-footer" class="yui3-widget-ft height-resize-drag">\
								<div id="'+_id+'-modal-diag-resizer" class="diag-resize-drag"></div>\
								<div class="corner bl"></div>\
								<div class="top-bottom-body width-resizer"></div>\
								<div class="corner br"></div>\
							</div>\
						</div>';
var _header = '<div class="corner tl"></div>\
								<div class="top-bottom-body"></div>\
								<div class="corner tr"></div>\
								<div id="wspace-dock-top-bar" class="expand-collapse-bar">\
									<div class="expand-collapse-arrows"></div>\
								</div>';

var _footer ='<div class="corner bl"></div>\
								<div class="top-bottom-body"></div>\
								<div class="corner br"></div>';
		return {
			init: function() {
				_node = R8.Utils.Y.one('#'+_id+'-panel-item');

				R8.Utils.Y.one('#page-container').append(dockTpl);
				_modalNode = R8.Utils.Y.one('#'+_id+'-modal');
				_modalContentNode = R8.Utils.Y.one('#'+_id+'-modal-content');
				_modalHeaderNode = R8.Utils.Y.one('#'+_id+'-modal-header');
				var that = this;
				_modalHeaderNode.on('click',function(Y){ that.close(); that.get('node').removeClass('active'); });

				_panelPlugin = new R8.Dock2[_pluginName]({'modalContentNode':_modalContentNode});

//				var _right = _listNode.get('region').right - _listNode.get('region').left;
//				dialogNode.setStyles({display:'block',top:'100px',right:_right});
//var modalId = _id;
				YUI(YUI_config).use('overlay','node','event','dd','dd-proxy', function(Y) {
				    _overlay = new Y.Overlay({
				        srcNode:'#'+_id+'-modal',
						width:_modalCfg['width']+'px',
						height:_modalCfg['height']+'px',
//						bodyContent: '<div class="body">this is a test</div>',
//				        width:_modalWidth+'px',
//				        height:_modalHeight+'px',
						align: {
							node: '#'+_listNode.get('id'),
							points: ['tr','tl']
						}
				    });

/*					_overlay = new Y.Overlay({
						id:_id+'-modal',
						width:"260px",
						height:"260px",
						headerContent: _header,
						bodyContent: "Click the 'Align Next' button to try a new alignment",
						footerContent: _footer,
						zIndex:51,
						align: {
							node: '#'+_listNode.get('id'),
							points: ['tr','tl']
						},
						render: '#page-container'
					});
*/
				    _overlay.render();
					_modalNode.get('parentNode').setStyle('display','none');

					Y.all('#'+_id+'-modal .width-resizer').each(function(){
						var innerWidth = _modalCfg['width'] - 10;
						this.setStyle('width',innerWidth+'px');
					});

//					_modalNode = R8.Utils.Y.one('#'+modalId+'-modal');
//					_modalNode.addClass('panel-modal');

					if(typeof(_modalCfg['fixed_size']) == 'undefined' || _modalCfg['fixed_size'] == false) {
						that.resizeOn();
					}
				});
			},
/*
 						fixed_size: false,
						min_height: 150,
						min_width: 150,
						max_height: 500,
						max_width: 500

 */
			resizeOn: function() {
				var that = this;
				YUI(YUI_config).use('dd',function(Y){
					_widthResizer = new Y.DD.Drag({
						node: '#'+_id+'-modal-resize-width'
					});
					_widthResizer.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});
					_widthResizer.on('drag:drag',function(e){
						var x1 = e.pageX;
						var x2 = _modalNode.get('region').right;
						var newWidth = x2-x1;
						if (newWidth > _modalCfg['max_width']) {
							newWidth = _modalCfg['max_width'];
						} else if(newWidth < _modalCfg['min_width'])  {
							newWidth = _modalCfg['min_width'];
						}

						_overlay.set('width',newWidth+'px');
						that.realignModal();
						Y.all('#'+_id+'-modal .width-resizer').each(function(){
							var innerWidth = newWidth - 10;
							this.setStyle('width',innerWidth+'px');
						});
					});

					_heightResizer = new Y.DD.Drag({
						node: '#'+_id+'-modal-footer'
					});
					_heightResizer.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});
					_heightResizer.on('drag:drag',function(e){
						var y2 = e.pageY;
						var y1 = _modalNode.get('region').top;
						var newHeight = y2-y1;
						if (newHeight > _modalCfg['max_height']) {
							newHeight = _modalCfg['max_height'];
						} else if(newHeight < _modalCfg['min_height'])  {
							newHeight = _modalCfg['min_height'];
						}
						_overlay.set('height',newHeight+'px');
					});

					_diagResizer = new Y.DD.Drag({
						node: '#'+_id+'-modal-diag-resizer'
					});
					_diagResizer.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});
					_diagResizer.on('drag:drag',function(e){
						var x1 = e.pageX;
						var x2 = _modalNode.get('region').right;
						var newWidth = x2-x1;
						if (newWidth > _modalCfg['max_width']) {
							newWidth = _modalCfg['max_width'];
						} else if(newWidth < _modalCfg['min_width'])  {
							newWidth = _modalCfg['min_width'];
						}

						var y2 = e.pageY;
						var y1 = _modalNode.get('region').top;
						var newHeight = y2-y1;
						if (newHeight > _modalCfg['max_height']) {
							newHeight = _modalCfg['max_height'];
						} else if(newHeight < _modalCfg['min_height'])  {
							newHeight = _modalCfg['min_height'];
						}

						_overlay.set('height',newHeight+'px');
						_overlay.set('width',newWidth+'px');
						that.realignModal();
						Y.all('#'+_id+'-modal .width-resizer').each(function(){
							var innerWidth = newWidth - 10;
							this.setStyle('width',innerWidth+'px');
						});
					});
				});
				_modalNode.addClass('resizeable');
			},

			render: function() {
				return _tpl;
			},

			get: function(property) {
				switch(property) {
					case "node":
						return _node;
						break;
				}
			},

			opened: function() { return _opened; },

			close: function() {
				if(_opened) {
					_node.removeClass('open');
//					_node.removeClass('active');
					_modalNode.get('parentNode').setStyle('display','none');
				}
				_opened = false;
			},

			open: function() {
				if(!_opened) {
					this.refreshContent();
					_node.addClass('open');
					_modalNode.get('parentNode').setStyle('display','block');
					this.realignModal();
					_opened = true;
				}
			},

			realignModal: function() {
				_overlay.set('align',{node:'#'+_listNode.get('id'),points:['tr','tl']});
			},

			refreshContent: function() {
				var itemList = R8.Dock2.get('itemFocusList');
				var numItems = 0;
				for(var i in itemList) {
					numItems++;
				}
				if (numItems > 0) {
					_panelPlugin.refresh(itemList);
				}
			}
		}
	}

	R8.Dock2.usersPlugin = function(cfg) {
		var _cfg = cfg,
			_modalContentNode = cfg['modalContentNode'];

		return {
			refresh: function(items) {
//TODO: assuming only one for right now
				var item = null;
				for(var i in items) {
					item = items[i];
				}

				var params = {
					'cfg': {
						'data':'panel_id='+_modalContentNode.get('id'),
						'method': 'GET'
					},
//					'callbacks': {
//						'io:success':this.getPanelCfg
//					}
				};
console.log('going to call dock get users.....');
				R8.Ctrl.call(item.model+'/dock_get_users/'+item.id, params);
			}
		}
	}
	R8.Dock2.service_checksPlugin = function(cfg) {
	        var _cfg = cfg,
	                 _modalContentNode = cfg['modalContentNode'];
		return {
			refresh: function(items) {
//TODO: assuming only one for right now
				var item = null;
				for(var i in items) {
					item = items[i];
				}
				//console.log(item);

				var params = {
					'cfg': {
						'data':'panel_id='+_modalContentNode.get('id'),
						'method': 'GET'
					},
				};
console.log('going to call dock get service checks.....');
				R8.Ctrl.call(item.model+'/dock_get_service_checks/'+item.id, params);

			}
		}
	}
	R8.Dock2.applicationsPlugin = function(cfg) {
		var _cfg = cfg,
			_modalContentNode = cfg['modalContentNode'];

		return {
			refresh: function(items) {
//TODO: assuming only one for right now
				var item = null;
				for(var i in items) {
					item = items[i];
				}

				var that=this;
				var params = {
					'cfg': {
						'data':'panel_id='+_modalContentNode.get('id'),
						'method': 'GET'
					},
					'callbacks': {
						'io:success':function(ioId,responseObj) {
							eval("var response =" + responseObj.responseText);
//console.log(response);
							var content = response['application_node_dock_get_applications'].content[0].content;
							_modalContentNode.set('innerHTML',content);
							that.init();
						}
					}
				};
console.log('going to call dock get applications.....');
				R8.Ctrl.call(item.model+'/dock_get_applications/'+item.id, params);
			},
			init: function() {
//TODO: revisit to make more generic, shouldnt have to reference node explicitly, should be based on focus
				R8.Utils.Y.delegate('mouseenter',function(e) {
					var itemNode = R8.Utils.Y.one('#'+e.currentTarget.get('id'));
					itemNode.addClass('active');
				},'#node-application-list','.app-item',this);
				R8.Utils.Y.delegate('mouseleave',function(e) {
					var itemNode = R8.Utils.Y.one('#'+e.currentTarget.get('id'));
					itemNode.removeClass('active');
				},'#node-application-list','.app-item',this);
				R8.Utils.Y.delegate('click',function(e) {
					var itemNode = R8.Utils.Y.one('#'+e.currentTarget.get('id')),
						nodeId = itemNode.get('id'),
						componentId = nodeId.replace('app-','');

						var that=this;
						var params = {
							'cfg': {
								'data':'panel_id='+_modalContentNode.get('id'),
								'method': 'GET'
							},
							'callbacks': {
								'io:success':function(ioId,responseObj) {
									eval("var response =" + responseObj.responseText);
//console.log(response);
									var content = response['application_component_dock_edit'].content[0].content;
									_modalContentNode.set('innerHTML',content);
									that.initEditForm();
								}
							}
						};

						R8.Ctrl.call('component/dock_edit/'+componentId, params);
				},'#node-application-list','.app-item',this);
			},
			initEditForm: function() {
				var saveBtnNode = R8.Utils.Y.one('#component-edit-form-save');
				saveBtnNode.on('click',function(Y){
console.log('save button clicked....');
					var params = {
						'cfg' : {
							method : 'POST',
							form: {
								id : 'component-edit-form',
								upload: false
							}
						}
					};
					R8.Ctrl.call('component/save_attributes',params);
console.log('should have called to save attributes....');
				});
			}
		}
	}

	R8.Dock2.infoPlugin = function() {
//		var _cfg = cfg;

		return {
			refresh: function(items) {
//TODO: assuming only one for right now
				var item = null;
				for(var i in items) {
					item = items[i];
				}
console.log(item);
			}
		}
	}

}
