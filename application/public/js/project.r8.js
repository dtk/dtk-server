
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
			refreshTree: function() {

			}
		}
	};
}