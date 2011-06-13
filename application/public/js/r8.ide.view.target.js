
if (!R8.IDE.View.target) {

	R8.IDE.View.target = function(view) {
		var _view = view,
			_id = _view.id,
			_panel = _view.panel,

			_contentTpl = '<div id="'+_panel.get('id')+'-'+_view.id+'" class="target-viewspace"></div>',
			_contentNode = null,

			_initialized = false,

			//FROM WORKSPACE
			_viewSpaces = {},
			_viewSpaceStack = [],
			_currentViewSpace = null,
			_viewContext = 'node',

			_events = {};

		return {
			init: function() {
				_contentNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id);

				this.getWorkspaceDef();

				_initialized = true;
			},
			render: function() {
				return _contentTpl;
			},
			resize: function() {
				if(!_initialized) return;

/*
				var contentHeight = _node.get('region').height - _headerNode.get('region').height;
				_contentNode.setStyles({'height':contentHeight,'width':_node.get('region').width,'backgroundColor':'#FFFFFF'});
*/
			},
			get: function(key) {
				switch(key) {
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
				_contentNode.setStyle('display','block');
			},
			blur: function() {
				_contentNode.setStyle('display','none');
			},
			close: function() {
				_contentNode.purge(true);
				_contentNode.remove();
			},

//------------------------------------------------------
//these are target view specific functions
//------------------------------------------------------
/*
				var contextTpl = '<span class="context-span">'+viewSpaceDef.i18n+' > '+viewSpaceDef.object.display_name+'</span>';
				_contextBarNode.append(contextTpl);

				if(typeof(viewSpaceDef.items) != 'undefined') {
					this.addItems(viewSpaceDef.items, id);
					_viewSpaces[id].retrieveLinks(viewSpaceDef.items);
				}
*/
			getWorkspaceDef: function() {
				var that = this;
				var callback = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
					var targetViewDef = response.application_target_get_view_items.content[0].data;

					that.pushViewSpace(targetViewDef);
				}
				var params = {
					'cfg' : {
						method: 'POST',
						'data': ''
					},
					'callbacks': {
						'io:success':callback
					}
				};
				R8.Ctrl.call('target/get_view_items/'+_view.id,params);
			},
			pushViewSpace: function(viewSpaceDef) {
				if(_initialized == false) {
					var that=this;
					var initWaitCallback = function() {
						that.pushViewSpace(viewSpaceDef);
					}
					setTimeout(initWaitCallback,20);
					return;
				}

				viewSpaceDef.containerNodeId = _contentNode.get('id');

				var id = viewSpaceDef['object']['id'];
				_viewSpaces[id] = new R8.ViewSpace2(viewSpaceDef);
				_viewSpaces[id].init();
				_viewSpaceStack.push(id);
				_currentViewSpace = id;

//				var contextTpl = '<span class="context-span">'+viewSpaceDef.i18n+' > '+viewSpaceDef.object.display_name+'</span>';
//				_contextBarNode.append(contextTpl);

				if(typeof(viewSpaceDef.items) != 'undefined') {
					this.addItems(viewSpaceDef.items, id);
					_viewSpaces[id].retrieveLinks(viewSpaceDef.items);
				}

//				this.refreshNotifications();
			},
			addItems: function(items,viewSpaceId) {
				var vSpaceId = (typeof(viewSpaceId) == 'undefined') ? _currentViewSpace : viewSpaceId;
				if(!_viewSpaces[vSpaceId].isReady()) {
					var that = this;
					var addItemsCallAgain = function() {
						that.addItems(items,viewSpaceId);
					}
					setTimeout(addItemsCallAgain,20);
					return;
				}
				_viewSpaces[vSpaceId].addItems(items);
			},

		}
	};
}