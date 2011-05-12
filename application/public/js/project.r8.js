
if (!R8.Project) {

	R8.Project = function(projectDef) {
		var _def = projectDef,
			_wrapperNode = null,
			_rootNode = null,
			_leafNode = null,

			_targets = {},

			_events = {};

		return {
			init: function() {
				
			},
			get: function(key) {
				switch(key) {
					case "foo":
						break;
				}
			},
			renderTree: function(parentNode) {
//DEBUG
console.log(_def);

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
					targetsNode.append(_targets[targetId].renderTree());
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
					'core': {'animation':0},
					'plugins': ["themes","html_data"],
					'themes': {
						'theme': "r8",
						'dots': false
					}
				});

				_leafNode = R8.Utils.Y.one('#project-'+_def.id);

				_events['leaf_dblclick'] = R8.Utils.Y.delegate('dblclick',function(e){
					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-','');
				
					switch(leafType) {
						case "target":
							_targets[leafObjectId].loadMain();
							break;
					}
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
				var componentLeaf = {
					'node_id': 'component-template-'+componentTemplate.id,
					'type': 'application',
					'basic_type': 'application',
					'name': componentTemplate.display_name
				};
				var leafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': componentLeaf}));
				var ulNode = R8.Utils.Y.Node.create('<ul></ul>');
				for(var i in componentTemplate.implementations) {
					var impDef = componentTemplate.implementations[i];
					var implementationLeaf = {
						'node_id': 'implementation-'+impDef.id,
						'type': impDef.type,
						'basic_type': impDef.type,
						'name': 'cookbook'
					};
					var impNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': implementationLeaf}));
					impNode.append(this.renderFileTree(impDef.file_assets));
					ulNode.append(impNode);
				}
				leafNode.append(ulNode);

				return leafNode;
//				var ulNode2 = R8.Utils.Y.Node.create('<ul></ul>');
//				ulNode2.append(leafNode);

//				return ulNode2;
			},
			renderFileTree: function(file_assets) {
				var ulNode = R8.Utils.Y.Node.create('<ul></ul>');
				for(var f in file_assets) {
					switch(file_assets[f].model_name) {
						case "directory_asset":
							var ulDNode = R8.Utils.Y.Node.create('<ul></ul>');
							var dirLeaf = {
								'node_id': 'dir-asset-'+f+'-'+file_assets[f].display_name,
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
								'node_id': 'file-asset-'+file_assets[f].id,
								'type': 'file',
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
			}
		}
	};
}