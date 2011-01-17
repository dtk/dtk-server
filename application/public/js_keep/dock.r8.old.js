
if(!R8.Workspace.Dock) {

	(function(R8){

	R8.Workspace.Dock = function() {
		var _nodeId = 'wspace-dock-wrapper',
			_node = null,
			_display = 'none',
			_dockWidth = 250,
			_state = 'foo',
			_right = '0',
			_top = '0',

			_topbarNodeId = 'wspace-dock-topbar',
			_topbarNode = null,
			_topbarAnim = null,
			_bodyNodeId = 'wspace-dock-body',
			_bodyNode = null,
			_bodyAnim = null,
			_topbarAnimEvent = null,

			_panels = [],

			_setTopbarNode = function(e) {
				_topbarNode = R8.Utils.Y.one('#'+_topbarNodeId);
			},
			_setBodyNode = function(e) {
				_bodyNode = R8.Utils.Y.one('#'+_bodyNodeId);
			};

		return {
			init: function() {
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
						R8.Workspace.Dock.loadDockPanel(route);
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

/*
				_topbarAnim.on('end',function(e){
				});
				_bodyAnim.on('end',function(e){
				});
*/
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

			render: function(params) {
				_display = (!params['display']) ? 'none' : params['display'];
				_top = (!params['top']) ? '0' : params['top'];
				_right = (!params['right']) ? '0' : params['right'];

/*				var content = '<div id="'+_nodeId+'" style="display: '+_display+'; position: absolute; height: 400px; width: 250px; border: 3px solid #CCCCCC; background-color: #DDDDDD; right: '+_right+'px; top: '+_top+'px;">\
						<div id="wspace-dock-topbar" style="float: left; position: relative; height: 30px; width: 100%; background-color: #FFFFFF;">\
							<div id="wspace-dock-close" class="close-tab-temp"></div>\
						</div>\
						<div id="wspace-dock-body" style="overflow-x: hidden; overflow-y: scroll; position: relative; float: left; height: 360px; width: 240px;">\
						</div>\
					</div>';
				var content = '<div id="'+_nodeId+'" class="wspace-dock-container" style="display: '+_display+'; right: '+_right+'px; top: '+_top+'px;">\
							<div id="wspace-dock-topbar" class="wspace-dock-topbar-container">\
							</div>\
							<div id="wspace-dock-body" class="wspace-dock-body-container">\
							</div>\
					</div>';
*/

				var content = '<div id="'+_nodeId+'" class="wspace-dock-wrapper minimized" style="display: '+_display+'; right: '+_right+'px; top: '+_top+'px;">\
								<div class="topbar">\
									<div class="corner tl"></div>\
									<div class="top-bottom-body"></div>\
									<div class="corner tr"></div>\
								</div>\
								<div class="expand-collapse-bar">\
									<div class="expand-collapse-arrows expand"></div>\
								</div>\
								<div class="left-trans-bar"></div>\
								<div class="wspace-dock-maximized">\
									<div id="wspace-dock-topbar" class="wspace-dock-topbar-container"></div>\
									<div id="wspace-dock-body" class="wspace-dock-body-container"></div>\
								</div>\
								<div class="wspace-dock-minimized">\
									<div id="wspace-dock-panel-list" class="wspace-dock-panel-list">\
										<div id="component-panel-item" class="panel-item">\
											<div style="float: left; height: 22px; width: 22px; margin-top: 4px;">\
												<div class="applications-panel-btn"></div>\
											</div>\
											<div class="label">Applications</div>\
										</div>\
										<div id="component-panel-item" class="panel-item">\
											<div style="float: left; height: 22px; width: 22px; margin-top: 4px;">\
												<div class="languages-panel-btn"></div>\
											</div>\
											<div class="label">Languages</div>\
										</div>\
										<div id="component-panel-item" class="panel-item">\
											<div style="float: left; height: 22px; width: 22px; margin-top: 4px;">\
												<div class="service-checks-panel-btn"></div>\
											</div>\
											<div class="label">Service Checks</div>\
										</div>\
										<div id="component-panel-item" class="panel-item">\
											<div style="float: left; height: 22px; width: 22px; margin-top: 4px;">\
												<div class="components-panel-btn"></div>\
											</div>\
											<div class="label">Components</div>\
										</div>\
									</div>\
								</div>\
								<div class="right-trans-bar"></div>\
								<div class="bottombar">\
									<div class="corner bl"></div>\
									<div class="top-bottom-body"></div>\
									<div class="corner br"></div>\
								</div>\
								</div>';

				return content;
			},

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

				_panels.push(new R8.Workspace.Dock.panel(panelCfg));
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

			show: function() {
				if(_node == null) _node = R8.Utils.Y.one('#'+_nodeId);

				_node.setStyle('display','block');
			},
			hide: function() {
				if(_node == null) _node = R8.Utils.Y.one('#'+_nodeId);

				_node.setStyle('display','none');
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
			},

		}
	}();

	})(R8)

//-------DOCK PANEL---------------

	R8.Workspace.Dock.panel = function(cfg) {
		var _cfg = cfg,
			_title = cfg['title']['i18n'],
			_topbarNode = cfg['topbarNode'],
			_bodyNode = cfg['bodyNode'],
			_indexPos = cfg['indexPos'],
			_bodyContent = cfg['bodyContent'],
			_hasBackBtn = (typeof(cfg['backBtn']) !='undefined') ? cfg['backBtn'] : true;

		return {
			init: function(scroll) {
				var scrollStyle = (scroll == true) ? 'overflow-y: scroll;' : '';
				var backBtnContent = (_hasBackBtn == true) ? '<div id="back-btn" class="back-btn"></div>' : '';
				var titleItem = '<div class="topbar-title-item">\
								'+backBtnContent+'\
								<div class="title">'+_title+'</div>\
							</div>';

				var bodyItem = '<div id="wspace-dock-body-'+_indexPos+'" class="wspace-body-item" style="'+scrollStyle+'">\
								'+_bodyContent+'\
							</div>';

				_bodyNode.append(bodyItem);
				_topbarNode.append(titleItem);
			},
			destroy: function() {
				var bdyChildren = _bodyNode.get('children'),
					tpbarChildren = _topbarNode.get('children');

				bdyChildren.item(_indexPos).purge(true);
				bdyChildren.item(_indexPos).remove();
				tpbarChildren.item(_indexPos).purge(true);
				tpbarChildren.item(_indexPos).remove();
			}
		}
	}

}
