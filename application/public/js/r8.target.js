
if (!R8.Target) {

	R8.Target = function(targetDef) {
		var _def = targetDef,
			_treeObj = targetDef,

			_project = targetDef.projectObj,

			_leafNode = null,
			_leafBodyNode = null,
			_nodesLeafNode = null,

			_nodes = {},
			_nodeGroups = {},

			_views = {},

			_events = {};

		return {
			init: function() {
				this.requireView('editor');
				this.requireView('project');

				for(var i in _treeObj.nodes) {
					var nodeId = _treeObj.nodes[i].id;
					_nodes[nodeId] = new R8.Node({'obj': _treeObj.nodes[i]});
					_nodes[nodeId].init({});
				}
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _def.id;
						break;
					case "type":
						return "target";
						break;
					case "iaas_type":
						return _def.iaas_type;
						break;
					case "name":
//						return _def.name;
						return _def.display_name;
						break;
					case "nodes":
						return _nodes;
						break;
				}
			},
//-----------------------------------------------
//VIEW RELATED METHODS-------------------
//-----------------------------------------------
			requireView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') _views[viewType] = {};


				_views[viewType] = new R8.IDE.View[viewType].target({'obj':this});

			},
			getView: function(viewType) {
				return _views[viewType];
			},
			renderView: function(viewType) {
				return _views[viewType].render();
			},
			initView: function(viewType) {
				return _views[viewType].init();
			},
/*
			renderView: function() {
				var viewTpl = '<div id="target-viewspace-'+_def.id+'" class="target-viewspace"></div>';

				return viewTpl;
			},
*/
			initEvents: function() {
				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNode.get('id'));

				_events['leaf_dblclick'] = _leafBodyNode.on('click',function(e){
					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

					R8.IDE.openEditorView(this.getView('editor'));
					e.halt();
					e.stopImmediatePropagation();
				},this);
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
/*
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
*/
//-----------------------------------------------
//END VIEW RELATED METHODS---------------
//-----------------------------------------------


//-----------------------------------------------
//EDITOR VIEW RELATED METHODS--------------------
//-----------------------------------------------


//-----------------------------------------------
//END EDITOR VIEW RELATED METHODS----------------
//-----------------------------------------------

		}
	};
}