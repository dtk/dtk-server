
if (!R8.IDE.View.port) { R8.IDE.View.port = {}; }

if (!R8.IDE.View.port.editor_target) {

	R8.IDE.View.port.editor_target = function(port,node) {
		var _panel = null,
			_port = port,
			_node = node,

			_idPrefix = "port-",
			_nodeId = _idPrefix+_port.get('id'),
			_contentNode = null,

			_events = {};

		return {
			init: function() {
//				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNode.get('id'));

				_leafNode = R8.Utils.Y.one('#'+_nodeId);

				this.initEvents();
				_initialized = true;

				return _initialized;
			},
			initEvents: function() {
/*
				_events['leaf_dblclick'] = _leafBodyNode.on('click',function(e){

					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

					R8.IDE.openEditorView(_target);

					e.halt();
					e.stopImmediatePropagation();
				},this);
*/
			},
			render: function() {
//				var basicPortTpl = '<div id="'+_nodeId+'" class="basic-port port available '+_port.get('direction')+'-'+_port.get('location')+'"></div>';
				var basicPortTpl = '<div id="'+_nodeId+'" class="port available '+_port.get('direction')+'-'+_port.get('location')+'"></div>';
				_node = R8.Utils.Y.Node.create(basicPortTpl);

				return _node;
			},
			resize: function() {
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _nodeId;
						break;
					case "id-prefix":
						return "foo";
						break;
					case "port":
						return _port;
						break;
					case "def":
						return _port.get('def');
						break;
					case "node":
						return _node;
						break;
					case "region":
						return _node.get('region');
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