
if (!R8.IDE.View.project) { R8.IDE.View.project = {}; }

if (!R8.IDE.View.project.target) {

	R8.IDE.View.project.target = function(viewDef) {
		var _panel = viewDef.panel,
			_obj = viewDef.obj,
			_idPrefix = "target-leaf-",

			_leafNodeId = '',
			_leafNode = null,
			_leafBodyNodeId = '',
			_leafBodyNode = null,
			_nodesLeafNode = null,
			_nodesListNode = null,

			_nodes = {},
			_nodeGroups = {},
			_views = {},

			_leafDef = {
				'node_id': 'target-'+_obj.get('id'),
				'type': 'target-'+_obj.get('iaas_type'),
				'name': _obj.get('name'),
				'basic_type': 'target'
			},

			_events = {};

		return {
			init: function() {
//				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNode.get('id'));

				_leafNode = R8.Utils.Y.one('#'+_leafNodeId);
				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNodeId);

				this.initEvents();
				_initialized = true;

				return _initialized;
			},
			initEvents: function() {
				_events['leaf_dblclick'] = _leafBodyNode.on('click',function(e){

					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

					R8.IDE.openEditorView(_obj);

					e.halt();
					e.stopImmediatePropagation();
				},this);
			},
			render: function() {
				_leafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': _leafDef}));
				_leafNodeId = _leafNode.get('id');

				_leafBodyNode = _leafNode.get('children').item(0);
				_leafBodyNodeId = _leafBodyNode.get('id');

/*
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
					'node_id': 'target-nodes-'+_obj.get('id'),
					'type': 'nodes',
					'basic_type': 'nodes',
					'name': 'Nodes'
				};
				_nodesLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': nodesLeaf}));

				_nodesListNode = R8.Utils.Y.Node.create('<ul></ul>');
				nodes = _obj.get('nodes');

				for(var n in nodes) {
					this.addNode(nodes[n]);
//					var nodeId = nodes[n].id;
//					_nodes[nodeId] = new R8.Node(nodes[n]);
//					ulNode.append(_nodes[nodeId].renderTree());
				}

				_nodesLeafNode.append(_nodesListNode);

				_leafNode.append(_nodesLeafNode);

/*
				for(var n in nodes) {
					var nodeId = nodes[n].id;
					_nodes[nodeId] = new R8.Node(nodes[n]);
					ulNode.append(_nodes[nodeId].renderTree());
				}
				_nodesLeafNode.append(ulNode);
				var ulNode2 = R8.Utils.Y.Node.create('<ul></ul>');
				ulNode2.append(_nodesLeafNode);
				_leafNode.append(ulNode2);
*/
				return _leafNode;
			},
			resize: function() {
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _id;
						break;
					case "id-prefix":
						return "foo";
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
//TARGET VIEW FUNCTIONS
//--------------------------------------
			addNode: function(node) {
				_nodesListNode.append(node.renderView('project'));
			}
		}
	};
}