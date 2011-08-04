
if (!R8.Project) {

	R8.Project = function(projectDef) {
		var _def = projectDef,
			_wrapperNode = null,
			_rootNode = null,
			_leafNode = null,

			_implementations = {},
			_targets = {},

			_events = {};

		return {
			init: function() {
				for(var t in _targets) {
//					_targets[targetId].initView('project');
					_targets[t].getView('project').init();
				}
//DEBUG
console.log('INIT CALLED INSIDE OF PROJECT....');
			},
			get: function(key) {
				switch(key) {
					case "foo":
						break;
				}
			},
			renderTree: function(parentNode) {
				var wrapperTpl = '<div id="project-tree-'+_def.id+'" class="project-view-content jstree jstree-default jstree-r8">\
								  </div>';
				_wrapperNode = R8.Utils.Y.Node.create(wrapperTpl);
/*
				var wrapperTpl = '<div id="project-tree-'+_def.id+'" class="project-view-content jstree jstree-default jstree-r8">\
									<ul>'+rootLeafTpl+'</ul>\
								  </div>';
*/
//				_wrapperNode = R8.Utils.Y.Node.create(wrapperTpl);

				var rootLeaf = {
					'node_id': 'project-'+_def.id,
					'type': 'project',
					'basic_type': 'project',
					'name': _def.name
				};

				var rootNodeTpl = '<ul>'+R8.Rtpl['project_tree_leaf']({'leaf_item': rootLeaf})+'</ul>';
				_rootNode = R8.Utils.Y.Node.create(rootNodeTpl);

				_wrapperNode.append(_rootNode);
				parentNode.append(_wrapperNode);
				_leafNode = R8.Utils.Y.one('#project-'+_def.id);

				var targetsNode = R8.Utils.Y.Node.create('<ul></ul>');
				for(var t in _def.tree.targets) {
					var targetId = _def.tree.targets[t].id;

					_targets[targetId] = new R8.Target(_def.tree.targets[t]);

					//TODO: maybe pass init params to make for leaner loading at times
					_targets[targetId].init({});

					targetsNode.append(_targets[targetId].renderView('project'));

//					targetsNode.append(_targets[targetId].renderTree());

//					targetsContent = targetsContent + _targets[targetId].renderTree();
				}

				_leafNode.append(targetsNode);

				_leafNode.append(this.renderComponentsTree());
/*
				if(targetsContent !='') {
					_leafNode.append('<ul>'+targetsContent+'</ul>');
				}
*/

				$('#project-tree-'+_def.id).jstree({
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

				_leafNode = R8.Utils.Y.one('#project-'+_def.id);
/*
				for(var t in _targets) {
//					_targets[targetId].initView('project');
					_targets[t].getView('project').init();
				}
*/

				_events['leaf_dblclick'] = R8.Utils.Y.delegate('dblclick',function(e){
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

/*
<li id="{%=leaf_item[:node_id]%}" rel="{%=leaf_item[:type]%}" class="jstree-leaf">
	<a href="#">{%=leaf_item[:name]%}</a>
</li>

<ul id="foo-tree">
	<li id="node_2" rel="project" class="jstree-open">
		<a href="#" class="">Chef 01</a>
*/
			},
			loadFileInEditor: function(fileId) {
				R8.Editor.loadFile(fileId);
			},
			renderComponentsTree: function() {
				var projectComponentsLeaf = {
					'node_id': 'components-'+_def.id,
					'type': 'components',
					'basic_type': 'components',
					'name': 'Components'
				};
				var compsLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': projectComponentsLeaf}));

				var ulNode = R8.Utils.Y.Node.create('<ul></ul>');
				for(var i in _def.tree.component_templates) {
					ulNode.append(this.renderImplementationTree(_def.tree.component_templates[i]));
				}
				compsLeafNode.append(ulNode);
				var ulNode2 = R8.Utils.Y.Node.create('<ul></ul>');
				ulNode2.append(compsLeafNode);

				return ulNode2;
			},
			renderImplementationTree: function(componentTemplate) {
/*
				var componentLeaf = {
					'node_id': 'component-template-'+componentTemplate.id,
					'type': 'application',
					'basic_type': 'application',
					'name': componentTemplate.display_name
				};
				var leafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': componentLeaf}));
*/				var ulNode = R8.Utils.Y.Node.create('<ul></ul>');

				for(var i in componentTemplate.implementations) {
					var impDef = componentTemplate.implementations[i];
					var implementationLeaf = {
						'node_id': 'implementation-'+impDef.id,
						'type': impDef.type,
						'basic_type': impDef.type,
						'name': componentTemplate.display_name+'(v'+impDef.version+')'
					};
					var impNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': implementationLeaf}));
					impNode.append(this.renderFileTree(impDef.file_assets));
					ulNode.append(impNode);
				}
//				leafNode.append(ulNode);

//				return leafNode;
				return ulNode;

//				var ulNode2 = R8.Utils.Y.Node.create('<ul></ul>');
//				ulNode2.append(leafNode);

//				return ulNode2;
			},
			renderFileTree: function(file_assets) {
				file_assets.sort(this.sortAssetTree);

				var ulNode = R8.Utils.Y.Node.create('<ul></ul>');
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