
if (!R8.IDE.View.chefDebugger) {

	R8.IDE.View.chefDebugger = function(view) {
		var _view = view,
			_id = _view.id,
			_panel = _view.panel,
			_pendingDelete = {},

			_modalNoe = null,
			_modalNodeId = 'chef-debugger-'+_id+'-modal',
			_shimNodeId = null,
			_shimNode = null,

			_alertNode = null,
			_alertNodeId = null,

//DEBUG
//			_contentTpl = '<div id="'+_panel.get('id')+'-'+_view.id+'" class="target-viewspace"></div>',
			_contentTpl = '<div id="'+_panel.get('id')+'-chef-debugger-wrapper" style="">\
								foobard!!!!!\
						</div>',

			_contentWrapperNode = null,
			_contentNode = null,

			_initialized = false,

			//FROM WORKSPACE
			_viewSpaces = {},
			_viewSpaceStack = [],
			_currentViewSpace = null,
			_viewContext = 'node',

			_cmdBar = null,

			_events = {};

		return {
			init: function() {
//				_contentNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id);
				_contentWrapperNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id+'-wrapper');

				_initialized = true;
			},
			render: function() {
				return _contentTpl;
			},
			resize: function() {
				if(!_initialized) return;

				var pRegion = _panel.get('node').get('region');
				_contentWrapperNode.setStyles({'height':pRegion.height,'width':pRegion.width});

/*
				var contentHeight = _node.get('region').height - _headerNode.get('region').height;
				_contentNode.setStyles({'height':contentHeight,'width':_node.get('region').width,'backgroundColor':'#FFFFFF'});
*/
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _id;
						break;
					case "name":
						return _view.name;
						break;
					case "type":
						return _view.type;
						break;
				}
			},
			focus: function() {
				this.resize();
				_contentWrapperNode.setStyle('display','block');
			},
			blur: function() {
				_contentWrapperNode.setStyle('display','none');
			},
			close: function() {
				_contentWrapperNode.purge(true);
				_contentWrapperNode.remove();
			},

//------------------------------------------------------
//these are target view specific functions
//------------------------------------------------------


//---------------------------------------------
//alert/notification related
//---------------------------------------------
			showAlert: function(alertStr) {
				_alertNodeId = R8.Utils.Y.guid();

				var alertTpl = '<div id="'+_alertNodeId+'" class="modal-alert-wrapper">\
									<div class="l-cap"></div>\
									<div class="body"><b>'+alertStr+'</b></div>\
									<div class="r-cap"></div>\
								</div>',

					nodeRegion = _contentNode.get('region'),
					height = nodeRegion.bottom - nodeRegion.top,
					width = nodeRegion.right - nodeRegion.left,
					aTop = 0,
					aLeft = Math.floor((width-250)/2);

//				containerNode.append(alertTpl);
				_contentNode.append(alertTpl);
				_alertNode = R8.Utils.Y.one('#'+_alertNodeId);
				_alertNode.setStyles({'top':aTop,'left':aLeft,'display':'block'});
//return;
				YUI().use('anim', function(Y) {
					var anim = new Y.Anim({
						node: '#'+_alertNodeId,
						to: { opacity: 0 },
						duration: .7
					});
					anim.on('end', function(e) {
						var node = this.get('node');
						node.get('parentNode').removeChild(node);
					});
					var delayAnimRun = function(){
							anim.run();
						}
					setTimeout(delayAnimRun,2000);
				});
//				alert(alertStr);
			},

			shimify: function(nodeId) {
				var node = R8.Utils.Y.one('#'+nodeId),
					_shimNodeId = R8.Utils.Y.guid(),
					nodeRegion = node.get('region'),
					height = nodeRegion.bottom - nodeRegion.top,
					width = nodeRegion.right - nodeRegion.left;

				node.append('<div id="'+_shimNodeId+'" class="wspace-shim" style="height:'+height+'; width:'+width+'"></div>');
				_shimNode = R8.Utils.Y.one('#'+_shimNodeId);
				_shimNode.setStyle('opacity','0.8');
				_shimNode.on('click',function(Y){
					R8.Workspace.destroyShim();
				});
			},
			destroyShim: function() {
				_modalNode.purge(true);
				_modalNode.remove();
				_modalNode = null,

				_shimNode.purge(true);
				_shimNode.remove();
				_shimId = null;
				_shimNode = null;
			}

		}
	};
}