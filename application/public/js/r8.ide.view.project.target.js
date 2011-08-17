
if (!R8.IDE.View.project) { R8.IDE.View.project = {}; }

if (!R8.IDE.View.project.target) {

	R8.IDE.View.project.target = function(target) {
		var _target = target,
			_idPrefix = "target-leaf-",

			_leafNodeId = '',
			_leafNode = null,
			_leafBodyNodeId = '',
			_leafBodyNode = null,
			_childrenListNode = null,
			_childrenListNodeId = '',

			_nodesLeafNode = null,
			_nodesLeafNodeId = '',
			_nodeListNode = null,
			_nodeListNodeId = '',

			_leafDef = {
				'node_id': 'target-'+_target.get('id'),
				'type': 'target-'+_target.get('iaas_type'),
				'name': _target.get('name'),
				'basic_type': 'target'
			},

			_events = {};

		return {
			init: function() {
//				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNode.get('id'));

				_leafNode = R8.Utils.Y.one('#'+_leafNodeId);
				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNodeId);
				_childrenListNode = R8.Utils.Y.one('#'+_childrenListNodeId);

				_nodesLeafNode = R8.Utils.Y.one('#'+_nodesLeafNodeId);
				_nodeListNode = R8.Utils.Y.one('#'+_nodeListNodeId);

				var nodes = _target.get('nodes');
				for(var n in nodes) {
					nodes[n].getView('project').init();
				}

//console.log('SHOULD HAVE nodesListNode...');
//console.log(_nodeListNode);

/*
				var nodes = _target.get('nodes');
				for(var n in nodes) {
					nodes[n].initView('project');
				}
*/
				this.setupEvents();
				_initialized = true;

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
				_childrenListNode = R8.Utils.Y.Node.create('<ul id="target-'+_target.get('id')+'-children');
				_childrenListNodeId = _childrenListNode.get('id');

				var nodesLeaf = {
					'node_id': 'target-'+_target.get('id')+'-nodes',
					'type': 'nodes',
					'basic_type': 'nodes',
					'name': 'Nodes',
					'class': 'jstree-closed'
				};
				_nodesLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': nodesLeaf}));
				_nodesLeafNodeId = _nodesLeafNode.get('id');
				_nodeListNode = R8.Utils.Y.Node.create('<ul id="target-'+_target.get('id')+'-node-list"></ul>');
				_nodeListNodeId = _nodeListNode.get('id');

				var nodes = _target.get('nodes');
				for(var n in nodes) {
					this.addNode(nodes[n]);
				}

				_nodesLeafNode.append(_nodeListNode);
//				_nodesLeafNode.get('children').item(0).append(_nodeListNode);
				_childrenListNode.append(_nodesLeafNode);
				_leafNode.append(_childrenListNode);

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
			addNode: function(node,newNode) {
				var nodeLeafNode = node.getView('project').render(newNode);
				nodeLeafNode.addClass('jstree-open');

				//TODO: revisit, temp hack to work over the top of jstree library
//				if(_target.isInitialized()) {
				if(newNode == true) {
					nodeLeafNode.get('children').item(0).prepend('<ins class="jstree-icon">&nbsp;</ins>');
					nodeLeafNode.prepend('<ins class="jstree-icon">&nbsp;</ins>');
/*
var projectId = _target.get('project').get('id');
console.log('have project id:'+projectId)
//$('#project-tree-'+projectId).jstree("create", null, "last", { "attr" : { "rel" : this.id.toString().replace("add_", "") } });

/*
$('#project-tree-'+projectId).jstree(
	"create",
	"#"+_nodesLeafNode.get('id'),
	"last",
	{
		"attr" : {
			//"rel" : this.id.toString().replace("add_", ""),
			"id": "foopaa"
		},
		"state": "open"
	},
	function() {
console.log('added a new node via jstree interface....');
	}
);

return;
*/
				}

				if(_nodeListNode == null) {
					var tempNode = R8.Utils.Y.Node.create('<ul id="target-nodes-list-'+_target.get('id')+'"></ul>');
					_nodesLeafNode.append(tempNode);
					_nodeListNode = R8.Utils.Y.one('#target-nodes-list-'+_target.get('id'));
				}

				_nodeListNode.append(nodeLeafNode);

				if(newNode == true) {
					node.getView('project').init();
				}
			},
//TODO: make remove evented like add using IDE event framework
			removeNode: function(nodeRemoveId) {
				_nodeListNode.get('children').each(function(){
					var nodeLeafId = this.get('id');
					var nodeLeafId = nodeLeafId.replace('node-leaf-','');
					if(nodeLeafId == nodeRemoveId) {
						this.purge(true);
						this.remove();
					}
				});
			}
		}
	};
}