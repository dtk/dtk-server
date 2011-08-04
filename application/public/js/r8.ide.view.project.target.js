
if (!R8.IDE.View.project) { R8.IDE.View.project = {}; }

if (!R8.IDE.View.project.target) {

	R8.IDE.View.project.target = function(target) {
		var _target = target,
			_idPrefix = "target-leaf-",

			_leafNodeId = '',
			_leafNode = null,
			_leafBodyNodeId = '',
			_leafBodyNode = null,
			_nodesLeafNode = null,
			_nodesListNode = null,

//			_nodes = _target.get('nodes'),
//			_nodeGroups = {},

			_leafDef = {
				'node_id': 'target-'+_target.get('id'),
				'type': 'target-'+_target.get('iaas_type'),
				'name': _target.get('name'),
				'basic_type': 'target'
			},

			_events = {};

		return {
			init: function() {
//DEBUG
console.log('INSIDE OF PROJECT.TARGET INIT....');
//				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNode.get('id'));

				_leafNode = R8.Utils.Y.one('#'+_leafNodeId);
				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNodeId);
				_nodesLeafNode = R8.Utils.Y.one('#target-nodes-'+_target.get('id'));
				_nodesListNode = R8.Utils.Y.one('#target-nodes-list-'+_target.get('id'));

//console.log('SHOULD HAVE nodesListNode...');
//console.log(_nodesListNode);

/*
				var nodes = _target.get('nodes');
				for(var n in nodes) {
					nodes[n].initView('project');
				}
*/
				this.setupEvents();


				_initialized = true;

				var nodes = _target.get('nodes');
				for(var n in nodes) {
					nodes[n].getView('project').init();
				}
//				node.getView('project').init();

			},
			setupEvents: function() {
				_events['leaf_dblclick'] = _leafBodyNode.on('dblclick',function(e){

					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

					R8.IDE.openEditorView(_target);

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
					'node_id': 'target-nodes-'+_target.get('id'),
					'type': 'nodes',
					'basic_type': 'nodes',
					'name': 'Nodes'
				};
				var nodeLeafNode = R8.Utils.Y.Node.create('<ul>'+R8.Rtpl['project_tree_leaf']({'leaf_item': nodesLeaf})+'</ul>');

				_nodesListNode = R8.Utils.Y.Node.create('<ul id="target-nodes-list-'+_target.get('id')+'"></ul>');
				var nodes = _target.get('nodes');

				for(var n in nodes) {
					this.addNode(nodes[n]);
//					var nodeId = nodes[n].id;
//					_nodes[nodeId] = new R8.Node(nodes[n]);
//					ulNode.append(_nodes[nodeId].renderTree());
				}
//DEBUG
//console.log('+++++++++++++++++++');
//console.log(_nodesLeafNode.get('children').item(0));

				nodeLeafNode.get('children').item(0).append(_nodesListNode);
//				_nodesLeafNode.append(_nodesListNode);
console.log('Appending the nodesLeafNode to the target leaf node.....');
				_leafNode.append(nodeLeafNode);

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
				var nodeLeaf = node.renderView('project');

				//TODO: revisit, temp hack to work over the top of jstree library
				if(_target.isInitialized()) {
					nodeLeaf.get('children').item(0).prepend('<ins class="jstree-icon">&nbsp;</ins>');
					nodeLeaf.prepend('<ins class="jstree-icon">&nbsp;</ins>');
				}

				if(_nodesListNode == null) {
					var tempNode = R8.Utils.Y.Node.create('<ul id="target-nodes-list-'+_target.get('id')+'"></ul>');
					_nodesLeafNode.append(tempNode);
					_nodesListNode = R8.Utils.Y.one('#target-nodes-list-'+_target.get('id'));
				}
				
				_nodesListNode.append(nodeLeaf);

//				node.getView('project').init();
			}
		}
	};
}