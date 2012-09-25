
if (!R8.IDE.View.project) { R8.IDE.View.project = {}; }

if (!R8.IDE.View.project.project) {

	R8.IDE.View.project.project = function(project) {
		var _project = project,
			_idPrefix = "project-leaf-",

			_leafNodeId = '',
			_leafNode = null,
			_leafBodyNodeId = '',
			_leafBodyNode = null,
			_treeNode = null,
			_treeNodeId = '',

			_targetListNode = null,
			_targetListNodeId = '',

			_implementationLeafNode = null,
			_implementationListNode = null,

			_contextShimNodeId = '',
			_contextShimNode = null,
			_contextMenuOverlay = null,

			_leafDef = {
				'node_id': 'project-'+_project.get('id'),
				'type': 'project',
				'name': _project.get('name'),
				'basic_type': _project.get('type')
			},
			_events = {};

		return {
			init: function() {
				//-------------------------------------------------------------------
				//---------------BEGIN PROJECT TREE CREATION-------------------------
				//-------------------------------------------------------------------
				$('#project-tree-'+_project.get('id')).jstree({
//					'plugins': ["ui","themes","html_data","hotkeys","crrm","contextmenu"],
//					'plugins': ["themes","json_data","html_data","ui","crrm","cookies","search","hotkeys","contextmenu"],
//					'plugins': ["themes","json_data","html_data","ui","crrm","cookies","search","contextmenu"],
					'plugins': ["themes","json_data","html_data","ui","crrm","cookies","search"],

					"contextmenu":{
						"items": {
/*
							"rename":{
								"label": "Rename",
								"action": function(obj) {
//									this.rename(obj);
console.log('should be renaming this tree node now.....');
								}
							},
*/
							"rename":{},
							"remove":{
								"label": "Delete",
								"action": function(obj) {
									//console.log(obj.attr('id'));
									var splitter = obj.attr('id').split('-');
									if(splitter.length === 3) {
										var model = splitter[0];
										var modelId = splitter[2];
									}
									switch(model) {
										case "node":
									//DEBUG
									//console.log('should be deleting node.....');
											var targets = _project.get('targets');
											for(var t in targets) {
												if(targets[t].hasNode(modelId)) {
													targets[t].deleteNode(modelId);
												}
									//console.log('have target:'+t);
											}
											break;
									}
								}
							}
/*							"create":{
								"label": "Create",
								"separator_flase": false,
								"separator_after": true,
								"icon": "file",
								"action": function(obj) {
this.create(obj);
//console.log(arguments);
//console.log('should be creating tree node now.....');
								}
							}
*/
						}
					},

					'core': {'animation':0},
					'themes': {
						'theme': "r8",
						'dots': false
					}
				});

				_treeNode = R8.Utils.Y.one('#'+_treeNodeId);
				_leafNode = R8.Utils.Y.one('#'+_leafNodeId);
				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNodeId);
				_childrenListNode = R8.Utils.Y.one('#'+_childrenListNodeId);

				_implementationsLeafNode = R8.Utils.Y.one('#'+_implementationsLeafNodeId);
				_implementationsListNode = R8.Utils.Y.one('#'+_implementationsListNodeId);

				var targets = _project.get('targets');
				for(var t in targets) {
					targets[t].getView('project').init();
				}

				var implementations = _project.get('implementations');
				for(var i in implementations) {
					implementations[i].getView('project').init();
				}

				this.setupEvents();
				_initialized = true;
			},
			setupEvents: function() {
/*
				_events['leaf_dblclick'] = _leafBodyNode.on('dblclick',function(e){
					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

//					R8.IDE.openEditorView(_implementation);
//console.log('double clicked on project leaf:'+leafNodeId);

					e.halt();
					e.stopImmediatePropagation();
				},this);
*/

				_events['leaf_rtClick'] = R8.Utils.Y.delegate('contextmenu',function(e) {
					var targetNode = e.target.get('parentNode'),
						leafNodeId = targetNode.get('id'),
						leafType = targetNode.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-leaf-',''),
						leafLabel = targetNode.get('children').item(1).get('innerHTML');

					_contextShimNodeId = R8.Utils.Y.guid();
					var pageContainerNode = R8.Utils.Y.one('#page-container'),
						pageNodeRegion = pageContainerNode.get('region'),
						height = pageNodeRegion.height,
						width = pageNodeRegion.width;

					pageContainerNode.append('<div id="'+_contextShimNodeId+'" style="position: absolute; z-index: 1000; top:0px; height:'+height+'px; width:'+width+'px;"></div>');
					_contextShimNode = R8.Utils.Y.one('#'+_contextShimNodeId);
					_events['contextShimClick'] = _contextShimNode.on('click',function(e){
						this.clearContextMenu();
					},this);

					if(_contextMenuOverlay == null) {
						_contextMenuOverlay = new R8.Utils.Y.Overlay({
							bodyContent: '',
							visible: false,
							constrain: true,
							zIndex: 1001
						});
					}
					_contextMenuOverlay.render(R8.Utils.Y.one("body"));
					this.setContextMenu(leafType,leafObjectId);
					_contextMenuOverlay.set("xy", [e.pageX, e.pageY]);
					_contextMenuOverlay.show();

//					e.preventDefault();
//					e.halt();
//					e.stopImmediatePropagation();
				},_leafNode,'.leaf-body',this);

				_events['t_leaf_dblclick'] = R8.Utils.Y.delegate('dblclick',function(e) {
					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

					switch(leafType) {
/*
						case "target":
//							_targets[leafObjectId].loadMain();
R8.IDE.openEditorView(_targets[targetId]);
break;
							R8.IDE.openTarget({
								'id': leafObjectId,
								'name': leafLabel,
								'type': 'target'
							});
							break;
*/
						case "file":
							//this.loadFileInEditor(leafObjectId);
							R8.IDE.openFile({
								'id': leafObjectId,
								'name': leafLabel,
								'type': 'file'
							});
							break;
/*
						case "component":
							R8.IDE.openComponent({
								'id': leafObjectId,
								'name': leafLabel,
								'type': 'file'
							});
							break;
*/
					}
					e.halt();
					e.stopImmediatePropagation();
				},_leafNode,'.leaf-body',this);

			},
			clearContextMenu: function() {
				_events['contextShimClick'].detach();
				delete(_events['contextShimClick']);

				_contextShimNode.remove(true);
				_contextShimNode = null;
				_contextMenuOverlay.hide();
			},
			setContextMenu: function(contextModel,contextModelId) {
				var nodeContextDef = {
						"delete":{
							"label": "Delete",
							"clickCallback": function(e) {
								var model = e.target.getAttribute('data-model'),
									modelId = e.target.getAttribute('data-id');

								var targets = _project.get('targets');
								for(var t in targets) {
									if(targets[t].hasNode(modelId)) {
										targets[t].deleteNode(modelId);
									}
								}
							}
						}
					};

				var componentContextDef = {
						"delete":{
							"label": "Delete",
							"clickCallback": function(e) {
								var model = e.target.getAttribute('data-model'),
									modelId = e.target.getAttribute('data-id');

								var targets = _project.get('targets');
								for(var t in targets) {
									var nodes = targets[t].get('nodes');
									for(var n in nodes) {
										if(nodes[n].hasComponent(modelId)) {
											nodes[n].deleteComponent(modelId);
										}
									}
								}
							}
						}
					};

				switch(contextModel) {
					case "node":
						var contextDef = nodeContextDef,
							modelLabel = 'Node';
						break;
					case "component":
						var contextDef = componentContextDef,
							modelLabel = 'Component';
						break;
					default:
						_contextMenuOverlay.hide();
						this.clearContextMenu();
						return;
						break;
				}

				var bodyContent = '<div id="tree-context-menu" class="tree-context-menu">\
									  <ul id="tree-context-menu-actions">\
										<li><b>'+modelLabel+' Actions</b></li>\
										<li class="seperator"></li>\
									  </ul>\
								  </div>';

				_contextMenuOverlay.set('bodyContent',bodyContent);

				var actionsListNode = R8.Utils.Y.one('#tree-context-menu-actions');
				for(var action in contextDef) {
					var actionNodeId = action+'-'+contextModel+'-'+contextModelId,
						actionDef = contextDef[action];

					actionsListNode.append('<li><a id="'+actionNodeId+'" href="#" data-model="'+contextModel+'" data-id="'+contextModelId+'">'+actionDef.label+'</a></li>');

					R8.Utils.Y.one('#'+actionNodeId).on('click',actionDef.clickCallback,this);

					R8.Utils.Y.one('#'+actionNodeId).on('mouseup',function(e){
						_contextMenuOverlay.hide();
						this.clearContextMenu();
						R8.Utils.Y.one('#tree-context-menu').remove(true);
					},this);
				}
			},
			render: function() {
				var treeNodeTpl = '<div id="project-tree-'+_project.get('id')+'" class="project-view-content jstree jstree-default jstree-r8">\
								  </div>';
				_treeNode = R8.Utils.Y.Node.create(treeNodeTpl);
				_treeNodeId = _treeNode.get('id');

				var rootLeaf = {
					'node_id': 'project-'+_project.get('id'),
					'type': 'project',
					'basic_type': 'project',
					'name': _project.get('name')
				};

				var rootNodeTpl = '<ul>'+R8.Rtpl['project_tree_leaf']({'leaf_item': rootLeaf})+'</ul>';
				_rootNode = R8.Utils.Y.Node.create(rootNodeTpl);

				_leafNode = _rootNode.get('children').item(0);
				_leafNodeId = _leafNode.get('id');
				_leafBodyNode = _leafNode.get('children').item(0);
				_leafBodyNodeId = _leafBodyNode.get('id');

				_childrenListNode = R8.Utils.Y.Node.create('<ul id="project-'+_project.get('id')+'-children-list"></ul>');
				_childrenListNodeId = _childrenListNode.get('id');

				//------------------------------------
				//ADD TARGETS
				//------------------------------------
				var targets = _project.get('targets');
				for(var t in targets) {
					this.addTarget(targets[t]);
				}

				//------------------------------------
				//ADD IMPLEMENTATIONS
				//------------------------------------
				var projectImplementationsLeaf = {
					'node_id': 'project-'+_project.get('id')+'-implementation',
					'type': 'implementations',
					'basic_type': 'implementations',
					'name': 'Modules'
				};
				_implementationsLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': projectImplementationsLeaf}));
				_implementationsLeafNodeId = _implementationsLeafNode.get('id');
				_implementationsListNode = R8.Utils.Y.Node.create('<ul id="project-'+_project.get('id')+'-implementation-list"></ul>');
				_implementationsListNodeId = _implementationsListNode.get('id');

				var implementations = _project.get('implementations');
				for(var i in implementations) {
					this.addImplementation(implementations[i]);
				}
				_implementationsLeafNode.append(_implementationsListNode);
				_childrenListNode.append(_implementationsLeafNode);

				_leafNode.append(_childrenListNode);
				_treeNode.append(_rootNode);
				return _treeNode;
			},
			resize: function() {
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _id;
						break;
				}
			},
			focus: function() {
				this.resize();
			},
			blur: function() {
			},
			close: function() {
			},

//--------------------------------------
//IMPLEMENTATION VIEW FUNCTIONS
//--------------------------------------
			addTarget: function(target) {
					_childrenListNode.append(target.getView('project').render());
			},
			addImplementation: function(implementation,newImplementation) {
//DEBUG
//console.log(implementation);
//console.log('rendering the implementation:'+implementation.get('id'));
				var impLeafNode = implementation.getView('project').render(newImplementation);
				_implementationsListNode.append(impLeafNode);

			},
			renderFileTree: function(file_assets,ulNode) {
				file_assets.sort(this.sortAssetTree);

				if (typeof(ulNode) == 'undefined') {
					var ulNode = R8.Utils.Y.Node.create('<ul></ul>');
				}
				for(var f in file_assets) {
					switch(file_assets[f].model_name) {
						case "directory_asset":
							var ulDNode = R8.Utils.Y.Node.create('<ul></ul>');
							var dirLeaf = {
								'node_id': 'directory-'+f+'-'+file_assets[f].display_name,
//								'type': 'directory',
								'basic_type': 'directory',
								'name': file_assets[f].display_name
							};
							var fileNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': dirLeaf}));
							fileNode.append(this.renderFileTree(file_assets[f].children));
							ulDNode.append(fileNode);
							ulNode.append(ulDNode);
							break;
						case "file_asset":
							var fileLeaf = {
								'node_id': 'file-'+file_assets[f].id,
								'type': 'file',
								'basic_type': 'file',
//								'type': file_assets[f].model_name,
//								'basic_type': file_assets[f].type,
								'name': file_assets[f].file_name
							};
							var fileNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': fileLeaf}));
							ulNode.append(fileNode);
							break;
					}
				}
				return ulNode;
			},
			sortAssetTree: function(itemA, itemB) {
				if(itemA.model_name == 'directory_asset' && itemB.model_name == 'directory_asset') {
					return itemA.display_name > itemB.display_name ? 1 : -1;
				} else if(itemA.model_name == 'directory_asset' && itemB.model_name != 'directory_asset') {
					return -1;
				} else if(itemA.model_name != 'directory_asset' && itemB.model_name == 'directory_asset') {
					return 1;
				} else if(itemA.model_name == 'file_asset' && itemB.model_name == 'file_asset') {
					return itemA.file_name > itemB.file_name ? 1 : -1;
				}
			}
		}
	};
}