
if (!R8.Cmdbar) R8.Cmdbar = {};
if (!R8.Cmdbar.assemblies) {

	R8.Cmdbar.assemblies = function(def, target) {
		var _def = def,
			_id = _def['id'],
			_node = null,
			_renderList = [],
			_itemList = [],
			_selectedIndex = null,
			_oldSelectedIndex = null,
			_renderLimit = null,
			_assemblyDDel = null,
			_target = target,

			_events = {};

		return {
			init: function() {
				_node = R8.Utils.Y.one('#'+_target.get('id')+'-cmdbar-plugin-'+_id);
			},
			render: function() {
				var _itemTpl = '<div id="'+_target.get('id')+'-cmdbar-plugin-'+_id+'" class="item-wrapper plugin">\
									<div id="" class="item">Assemblies</div>\
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
				var id = this.get('id');
				var targetRegion = _target.get('node').get('region');
				var targetWidth = targetRegion.width;
				var listTpl = '<div id="assembly-list-container" style="width:'+targetWidth+'px;">\
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
				_assemblyDDel.destroy();
				delete(_assemblyDDel);
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

				R8.Ctrl.call('assembly/search',params);
			},
			setResults: function(ioId,responseObj) {
				eval("var response =" + responseObj.responseText);
				var assembly_list = response.application_assembly_search.content[0].data;

				var id=this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');
				var tmpStr = resultListNode.getStyle('width');
				var resultListWidth = tmpStr.replace('px','');
				var limit = Math.floor(resultListWidth/138)+1;

				resultListNode.setStyle('width',((limit+1)*138));

				_renderList = assembly_list;
				_itemList = assembly_list;
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
					resultListNode.append(R8.Rtpl['assembly_library_search']({'assembly':itemList[i]}));
				}
				resultListNode.get('children').item((_selectedIndex - renderStartIndex)).addClass('selected');
			},
			setupDD: function(){
				var id = _target.get('id');
				YUI().use('dd-delegate', 'dd-proxy', 'node', 'dd-drop-plugin', function(Y){
					var assemblyDDel = new Y.DD.Delegate({
						cont: '#'+id+'-list-body',
						nodes: 'div.assembly-result',
					});
					_assemblyDDel = assemblyDDel;
					_assemblyDDel.dd.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});

					_assemblyDDel.on('drag:mouseDown', function(e){
						var componentType = this.get('currentNode').get('children').item(0).getAttribute('data-type');
						componentType='composite';
						var targetNode = Y.one('#'+id);
//DEBUG
//console.log(id);
//console.log(targetNode);
//console.log(componentType);
						if(componentType == 'composite') {
							var dropGroup = 'dg-node-assembly';
							if(!targetNode.hasClass('yui3-dd-drop')) {
								var drop = new Y.DD.Drop({node:targetNode});
								drop.addToGroup([dropGroup]);
								drop.on('drop:enter',function(e){
//console.log('entered drop zone for assembly....');
								});
								drop.on('drop:hit',function(e){
//console.log('should be hitting the target with assembly....');
									var dropNode = e.drop.get('node');
									var compNode = e.drag.get('dragNode').get('children').item(0);
									var componentId = compNode.getAttribute('data-id');

//									var panelOffset = cmdbar.get('viewSpace').get('node').get('region').left;
									var panelOffset = targetNode.get('region').left;
									var assemblyLeftPos = e.drag.get('dragNode').get('region').left-panelOffset;

									//DEBUG
									var tempId = Y.guid();
									var e = {
										'componentId': componentId,
//										'componentDef': newComponentDef,
										'assemblyLeftPos': assemblyLeftPos
									};
//console.log('going to fire target assembly add event....');
									R8.IDE.fire('target-'+_target.get('model').get('id')+'-assembly-add',e);
								});
							}
						} else {
							var dropGroup = 'dg-component';
							var dropList = Y.all('#'+targetNode.get('id')+' div.'+dropGroup);

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
									});
								}
							});
						}
					});

					_assemblyDDel.on('drag:start', function(e){
						var drag = this.get('dragNode'), c = this.get('currentNode');
						drag.set('innerHTML',c.get('innerHTML'));
						drag.setAttribute('class', c.getAttribute('class')+' selected');
						this.dd.addToGroup('dg-node-assembly');
						drag.setStyles({
							opacity: .5,
						});
					});
				});
			}
		}
	}
}
