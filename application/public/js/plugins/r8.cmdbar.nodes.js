
if (!R8.Cmdbar) R8.Cmdbar = {};
if (!R8.Cmdbar.nodes) {
	R8.Cmdbar.nodes = function(def, target) {
		var _def = def,
			_id = _def['id'],
			_node = null,
			_renderList = [],
			_itemList = [],
			_selectedIndex = null,
			_oldSelectedIndex = null,
			_renderLimit = null,
			_nodeDDel = null,
			_target = target,

			_dropList = {},

			_events = {};

		return {
			init: function() {
				_node = R8.Utils.Y.one('#'+_target.get('id')+'-cmdbar-plugin-'+_id);
			},
			render: function() {
				var _itemTpl = '<div id="'+_target.get('id')+'-cmdbar-plugin-'+_id+'" class="item-wrapper plugin">\
									<div id="" class="item">Nodes</div>\
								</div>\
								<div id="" class="divider"></div>';

				return _itemTpl;
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _id;
						break;
					case "node":
						return _node;
						break;
					case "default_height":
					case "defaultHeight":
						return _def['default_height'];
						break;
				}
			},
			focus: function() {
//				_pluginInputNode.focus();

				var id = this.get('id');
				var targetRegion = _target.get('node').get('region');
				var targetWidth = targetRegion.width;
				var listTpl = '<div id="node-list-container" style="width:'+targetWidth+'px;">\
								 <div id="list-l-arrow-wrapper">\
									<div id="list-l-arrow"></div>\
								 </div>\
								<div id="list-body-wrapper" style="width:'+(targetWidth-80)+'px;">\
									<div id="'+id+'-list-body" style="width:'+(targetWidth-80)+'px;">\
									</div>\
								</div>\
								<div id="list-r-arrow-wrapper">\
									<div id="list-r-arrow"></div>\
								</div>\
							</div>';

				_target.get('pluginContentNode').set('innerHTML',listTpl);
				var _this=this;
				YUI().use("node", function(Y){
					_events['key_press'] = Y.one('document').on("keypress", function(e){
						if (e.keyCode == 37) {
							_oldSelectedIndex = _selectedIndex;
							_selectedIndex = (_selectedIndex==0) ? 0 : _selectedIndex=_selectedIndex-1;
							this.renderResults();
							e.halt();
						}
						else if (e.keyCode == 39) {
							var maxIndex = _renderList.length-1;

							if ((_selectedIndex + 1) > maxIndex) {
								e.halt();
								return;
							}
							_selectedIndex = (_selectedIndex==maxIndex) ? maxIndex : _selectedIndex=_selectedIndex+1;
							this.renderResults();
							e.halt();
						} else if(e.keyCode == 35) {
							var maxIndex = _renderList.length-1;
							_selectedIndex = maxIndex;
							this.renderResults();
						} else if(e.keyCode == 36) {
							_selectedIndex = 0;
							this.renderResults();
						}
					},_this);
				});
				this.runSearch();
//				this.setupDD();
			},
			blur: function() {
				if(typeof(_events['key_press']) != 'undefined') {
					_events['key_press'].detach();
					delete(_events['key_press']);
				}

				_target.get('pluginContentNode').set('innerHTML','');
				_nodeDDel.destroy();
				delete(_nodeDDel);
				_dropList = {};
			},
			runSearch: function() {
				var _this=this;

				var successCallback = function(ioId,responseObj) {
					_this.setResults(ioId,responseObj);
					_this.setupDD();
				}
				var callbacks = {
//					'io:start' : cmdbar.loadedTabs[tabIndex].startSearch,
//					'io:end' : cmdbar.loadedTabs[tabIndex].endSearch,
//					'io:renderComplete' : renderCompleteCallback,
					'io:success': successCallback
				};
				var params = {
					'cfg':{
						'data': ''
					},
					'callbacks':callbacks
				}

				R8.Ctrl.call('node/search',params);
			},
			setResults: function(ioId,responseObj) {
				eval("var response =" + responseObj.responseText);
				var node_list = response.application_node_search.content[0].data;

				var id=this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');
				var tmpStr = resultListNode.getStyle('width');
				var resultListWidth = tmpStr.replace('px','');
				var limit = Math.floor(resultListWidth/138)+1;

				resultListNode.setStyle('width',((limit+1)*138));

				_renderList = node_list;
				_itemList = node_list;
				_selectedIndex = 0;
				_oldSelectedIndex = 0;
				_renderLimit = limit;

				this.renderResults();
			},
			renderResults: function() {
				var id = this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');

				var itemList = _renderList;
				if (itemList.length == 0) {
					resultListNode.set('innerHTML','');
					return;
				}

				var renderStartIndex = _selectedIndex - (_renderLimit-2);
				renderStartIndex = (renderStartIndex < 0) ? 0 : renderStartIndex;
				var renderEndIndex = (_renderLimit) + renderStartIndex;

				resultListNode.set('innerHTML','');
				for(var i=renderStartIndex; i < renderEndIndex; i++) {
					if(typeof(itemList[i]) == 'undefined') continue;
					resultListNode.append(R8.Rtpl['node_library_search']({'node':itemList[i]}));
				}
				resultListNode.get('children').item((_selectedIndex - renderStartIndex)).addClass('selected');
			},
			setupDD: function(){
				var id = _target.get('id');
				YUI().use('dd-delegate', 'dd-proxy', 'dd-drop', 'dd-drop-plugin', 'node', function(Y){
					var nodeDDel = new Y.DD.Delegate({
						cont: '#'+id+'-list-body',
						nodes: 'div.node-result',
					});
					_nodeDDel = nodeDDel;

					_nodeDDel.dd.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false
					});

					_nodeDDel.on('drag:start', function(e){
						var drag = this.get('dragNode'), c = this.get('currentNode');
						drag.set('innerHTML',c.get('innerHTML'));
						drag.setAttribute('class', c.getAttribute('class')+' selected');
						this.dd.addToGroup('viewspace_drop');
						drag.setStyles({
							opacity: .5,
							zIndex: 1000
						});
					});

					_nodeDDel.on('drag:mouseDown', function(e){
						var dropGroup = 'dg-node';

						var targetViewNode = Y.one('#'+id);
						if (typeof(_dropList[id]) == 'undefined') {
							var targetNodeDrop = new Y.DD.Drop({
								node: targetViewNode
							});
							_dropList[id] = true;
							targetNodeDrop.addToGroup([dropGroup]);

							targetNodeDrop.on('drop:enter', function(e){
							});
							targetNodeDrop.on('drop:hit', function(e){
								var drop = e.drop.get('node');
								var dragClone = e.drag.get('dragNode').get('children').item(0);
//								var dragClone = e.drag.get('dragNode');
								var itemNodeId = dragClone.get('id');
								var tempId = Y.guid();
								dragClone.set('id', tempId);

								var contentXY = _target.get('node').getXY();
								var dragXY = dragClone.getXY();
								var dragRegion = dragClone.get('region');
								var dragLeft = dragXY[0] - (contentXY[0]);
								var dragTop = dragXY[1] - (contentXY[1]);

								dragClone.setStyles({
									'top': dragTop + 'px',
									'left': dragLeft + 'px'
								});

								var newNodeDef = {
									'id': tempId,
								//	'id': dragClone.getAttribute('data-id'),
									'status': 'temp',
									'is_deployed': false,
									'node_id': dragClone.getAttribute('data-id'),
									'data-model': 'node',
									'name': dragClone.getAttribute('data-name'),
									'target': drop.getAttribute('data-id'),
									'os_type': dragClone.getAttribute('data-os-type'),
									'components': [],
									'ui': {}
								};
								newNodeDef.ui['target-'+drop.getAttribute('data-id')] = {
									'top': dragTop + 'px',
									'left': dragLeft + 'px'
								};
								var e = {
									'nodeDef': newNodeDef
								};
								R8.IDE.fire('target-'+newNodeDef.target+'-node-add',e);
							});
						}
					});
				});
			}
		}
	}
}
