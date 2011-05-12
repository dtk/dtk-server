
if (!R8.Target) {

	R8.Target = function(targetDef) {
		var _def = targetDef,
			_leafNode = null,
			_leafBodyNode = null,
			_nodesLeafNode = null,

			_nodes = {},

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
			setLeafClickEvent: function() {
console.log('setting event...:'+_leafBodyNode.get('id'));
				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNode.get('id'));
				_leafBodyNode.on('click',function(e){
alert('Booyaaaakashaaa!!!');
				});
			},
			renderTree: function() {
				var targetLeaf = {
					'node_id': 'target-'+_def.id,
					'type': 'target-'+_def.iaas_type,
					'name': _def.display_name,
					'basic_type': 'target'
//					'name': _def.name
				};
				_leafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': targetLeaf}));
/*				_leafBodyNode = _leafNode.get('children').item(0);

				var that=this;
				var tester = function() {
					that.setLeafClickEvent();
				}
				setTimeout(tester,2000);
*/
/*
				_leafBodyNode.on('click',function(e){
console.log('should load target view....');
				});
*/
				var nodesLeaf = {
					'node_id': 'target-nodes-'+_def.id,
					'type': 'nodes',
					'basic_type': 'nodes',
					'name': 'Nodes'
				};
				_nodesLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': nodesLeaf}));

				var ulNode = R8.Utils.Y.Node.create('<ul></ul>');
				for(var n in _def.nodes) {
					var nodeId = _def.nodes.id;
					_nodes[nodeId] = new R8.Node(_def.nodes[n]);
					ulNode.append(_nodes[nodeId].renderTree());
				}
				_nodesLeafNode.append(ulNode);
				var ulNode2 = R8.Utils.Y.Node.create('<ul></ul>');
				ulNode2.append(_nodesLeafNode);
				_leafNode.append(ulNode2);

				return _leafNode;
			},
			refreshTree: function() {

			},
			loadMain: function() {
				var viewSpaceTpl = '<div id="target-viewspace-'+_def.id+'" class="target-viewspace"></div>';

				var contentDef = {
					'content': viewSpaceTpl,
					'title': 'Gyeah!!!',
					'panel': 'main'
				};
				R8.IDE.pushPanelContent(contentDef);
			}
		}
	};
}