
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

			_leafDef = {
				'node_id': 'project-'+_project.get('id'),
				'type': 'project',
				'name': _project.get('name'),
				'basic_type': _project.get('type')
			},
			_events = {};

		return {
			init: function() {
				_leafNode = R8.Utils.Y.one('#'+_leafNodeId);
				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNodeId);

				_treeNode = R8.Utils.Y.one('#'+_treeNodeId);
				_targetListNode = R8.Utils.Y.one('#'+_targetListNodeId);

				_implementationsLeafNode = R8.Utils.Y.one('#'+_implementationsLeafNodeId);
				_implementationsListNode = R8.Utils.Y.one('#'+_implementationsListNodeId);

//				_componentsLeafNode = R8.Utils.Y.one('#targets-'+_target.get('id'));
//				_componentsListNode = R8.Utils.Y.one('#targets-list-'+_target.get('id'));

				//-------------------------------------------------------------------
				//---------------BEGIN PROJECT TREE CREATION-------------------------
				//-------------------------------------------------------------------
				$('#project-tree-'+_project.get('id')).jstree({
//					'plugins': ["ui","themes","html_data","hotkeys","crrm","contextmenu"],
					'plugins': ["themes","json_data","html_data","ui","crrm","cookies","search","hotkeys","contextmenu"],
/*
					"contextmenu":{
						"items": {
							"rename":{
								"label": "Rename",
								"action": function(obj) {
									this.rename(obj);
								}
							}
						}
					},
*/
					'core': {'animation':0},
					'themes': {
						'theme': "r8",
						'dots': false
					}
				});

				var targets = _project.get('targets');
				for(var t in targets) {
					targets[t].getView('project').init();
				}

				this.setupEvents();
				_initialized = true;
			},
			setupEvents: function() {
				_events['leaf_dblclick'] = _leafBodyNode.on('dblclick',function(e){

					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

console.log('double clicked on project leaf:'+leafNodeId);

//					R8.IDE.openEditorView(_implementation);

					e.halt();
					e.stopImmediatePropagation();
				},this);

				_events['leaf_dblclick'] = R8.Utils.Y.delegate('dblclick',function(e) {
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

				//------------------------------------
				//ADD TARGETS
				//------------------------------------
				_targetListNode = R8.Utils.Y.Node.create('<ul ="project-'+_project.get('id')+'-target-list"></ul>');
				_targetListNodeId = _targetListNode.get('id');
				var targets = _project.get('targets');
				for(var t in targets) {
					this.addTarget(targets[t]);
				}

				_leafNode.append(_targetListNode);


				//------------------------------------
				//ADD IMPLEMENTATIONS
				//------------------------------------
				var projectImplementationsLeaf = {
					'node_id': 'project-'+_project.get('id')+'-implementation-list',
					'type': 'implementations',
					'basic_type': 'implementations',
					'name': 'Implementations'
				};
				_implementationsLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': projectImplementationsLeaf}));
				_implementationsLeafNodeId = _implementationsLeafNode.get('id');
				_implementationsListNode = R8.Utils.Y.Node.create('<ul ="project-'+_project.get('id')+'-implementation-list"></ul>');
				_implementationsListNodeId = _implementationsListNode.get('id');

				var implementations = _project.get('implementations');
				for(var i in implementations) {
					this.addImplementation(implementations[i]);
				}

				_implementationsLeafNode.append(_implementationsListNode);
				_leafNode.append(_implementationsLeafNode);

//				var ulNode2 = R8.Utils.Y.Node.create('<ul></ul>');
//				ulNode2.append(impsLeafNode);
//				_leafNode.append(ulNode2);


//				_leafNode = R8.Utils.Y.one('#project-'+_project.get('id').id);


/*
				var projectImplementationsLeaf = {
					'node_id': 'implementations-'+_def.id,
					'type': 'implementations',
					'basic_type': 'implementations',
					'name': 'Implementations'
				};
				var impsLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': projectImplementationsLeaf}));

				var impsListNode = R8.Utils.Y.Node.create('<ul></ul>');
//DEBUG
//console.log(_def.tree.implementations);

				var implementationsNode = R8.Utils.Y.Node.create('<ul></ul>');
				for(var i in _def.tree.implementations) {
					var implementationId = _def.tree.implementations[i].id;
					_implementations[implementationId] = new R8.Implementation(_def.tree.implementations[i]);
					//TODO: maybe pass init params to make for leaner loading at times
					_implementations[implementationId].init({});
					impsListNode.append(_implementations[implementationId].renderView('project'));
				}

				impsLeafNode.append(impsListNode);
				var ulNode2 = R8.Utils.Y.Node.create('<ul></ul>');
				ulNode2.append(impsLeafNode);
				_leafNode.append(ulNode2);
*/

//				_leafNode = R8.Utils.Y.one('#project-'+_project.get('id').id);

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
					_targetListNode.append(target.getView('project').render());
			},
			addImplementation: function(implementation) {
					_implementationsListNode.append(implementation.getView('project').render());
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