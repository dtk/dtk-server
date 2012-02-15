
if (!R8.Cmdbar) R8.Cmdbar = {};
if (!R8.Cmdbar.components) {

	R8.Cmdbar.components = function(def, target) {
		var _def = def,
			_id = _def['id'],
			_node = null,
			_renderList = [],
			_itemList = [],
			_selectedIndex = null,
			_oldSelectedIndex = null,
			_renderLimit = null,
			_compDDel = null,
			_target = target,

			_events = {};

		return {
			init: function() {
				_node = R8.Utils.Y.one('#'+_target.get('id')+'-cmdbar-plugin-'+_id);
			},
			render: function() {
				var _itemTpl = '<div id="'+_target.get('id')+'-cmdbar-plugin-'+_id+'" class="item-wrapper plugin">\
									<div id="" class="item">Components</div>\
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
				var listTpl = '<div id="component-list-container" style="width:'+targetWidth+'px;">\
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
				_compDDel.destroy();
				delete(_compDDel);
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

				R8.Ctrl.call('component/search',params);
			},
			setResults: function(ioId,responseObj) {
				eval("var response =" + responseObj.responseText);
				var component_list = response.application_component_search.content[0].data;

				var id=this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');
				var tmpStr = resultListNode.getStyle('width');
				var resultListWidth = tmpStr.replace('px','');
				var limit = Math.floor(resultListWidth/138)+1;

				resultListNode.setStyle('width',((limit+1)*138));

				_renderList = component_list;
				_itemList = component_list;
				_selectedIndex = 0;
				_oldSelectedIndex = 0;
				_renderLimit = limit;

				this.renderResults();
			},
			renderResults: function() {
				var id = this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');

				_itemList = _renderList;
				if (_itemList.length == 0) {
					resultListNode.set('innerHTML','');
					return;
				}

				var renderStartIndex = _selectedIndex - (_renderLimit-2);
				renderStartIndex = (renderStartIndex < 0) ? 0 : renderStartIndex;
				var renderEndIndex = (_renderLimit) + renderStartIndex;

/*
				if(!this.componentSearchShiftNeeded()) {
					resultListNode.get('children').item(oldSelectedIndex).removeClass('selected');
					resultListNode.get('children').item(selectedIndex).addClass('selected');
					return;
				}
*/
				resultListNode.set('innerHTML','');
				for(var i=renderStartIndex; i < renderEndIndex; i++) {
					if(typeof(_itemList[i]) == 'undefined') continue;
					resultListNode.append(R8.Rtpl['component_library_search']({'component':_itemList[i]}));
				}
				resultListNode.get('children').item((_selectedIndex - renderStartIndex)).addClass('selected');
			},
			setupDD: function(){
				var id = _target.get('id');
				YUI().use('dd-delegate', 'dd-proxy', 'node', 'dd-drop-plugin', function(Y){
					var compDDel = new Y.DD.Delegate({
						cont: '#'+id+'-list-body',
						nodes: 'div.component-result',
					});
					_compDDel = compDDel;
					_compDDel.dd.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});

					_compDDel.on('drag:mouseDown', function(e){
						var componentType = this.get('currentNode').get('children').item(0).getAttribute('data-type');
						componentType='component';
						var targetNode = Y.one('#'+id);

						if(componentType == 'composite') {
							var dropGroup = 'dg-node-assembly';
							if(!vspaceNode.hasClass('yui3-dd-drop')) {
								var drop = new Y.DD.Drop({node:vspaceNode});
								drop.addToGroup([dropGroup]);
								drop.on('drop:enter',function(e){
								});
								drop.on('drop:hit',function(e){
									var dropNode = e.drop.get('node');
									var compNode = e.drag.get('dragNode').get('children').item(0);
									var componentId = compNode.getAttribute('data-id');

									var panelOffset = cmdbar.get('viewSpace').get('node').get('region').left;
									var assemblyLeftPos = e.drag.get('dragNode').get('region').left-panelOffset;
//DEBUG
//									R8.Workspace.addAssemblyToViewspace(componentId,'node',assemblyLeftPos,dropNode);
//									cmdbar.get('viewSpace').addAssemblyToViewspace(componentId,'node',assemblyLeftPos,dropNode);
								});
							}
						} else {
							var dropGroup = 'dg-component';
							var dropList = Y.all('#'+_target.get('node').get('id')+' div.'+dropGroup);

							dropList.each(function(){
								if(!this.hasClass('yui3-dd-drop')) {
									var drop = new Y.DD.Drop({node:this});
									drop.addToGroup([dropGroup]);
									drop.on('drop:enter',function(e){
									});
									drop.on('drop:hit',function(e){
										var dropNode = e.drop.get('node');
										var compNode = e.drag.get('dragNode').get('children').item(0);
										var componentId = compNode.getAttribute('data-id');

										//DEBUG
										var tempId = Y.guid();
										var newComponentDef = {
											'id': tempId,
											'node_id': dropNode.getAttribute('data-id'),
											'component_id': componentId,
											'ui': {}
										};
										var e = {
											'componentDef': newComponentDef
										};
										R8.IDE.fire('node-'+newComponentDef.node_id+'-component-add',e);
//DEBUG
//console.log(e);
									});
								}
							});
						}
					});

					_compDDel.on('drag:start', function(e){
//DEBUG
//console.log('drag start on component is happening....');
						var drag = this.get('dragNode'), c = this.get('currentNode');
						drag.set('innerHTML',c.get('innerHTML'));
						drag.setAttribute('class', c.getAttribute('class')+' selected');
						this.dd.addToGroup('dg-component');
						drag.setStyles({
							opacity: .5,
						});
					});
				});
			}
		}
	}
}
/*

										<div id="'+id+'-plugin-component-search" class="item-wrapper plugin">\
											<div id="" class="item">Components</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-node-search" class="item-wrapper plugin">\
											<div id="" class="item">Nodes</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-assembly-search" class="item-wrapper plugin">\
											<div id="" class="item">Assemblies</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-logging" class="item-wrapper plugin">\
											<div id="" class="item">Logging</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-notifications" class="item-wrapper plugin">\
											<div id="" class="item">Notifications</div>\
										</div>\
										<div id="" class="divider"></div>\
*/