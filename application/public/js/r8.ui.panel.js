
if (!R8.UI.panelSet) {

	R8.UI.panelSet = function(panelSetDef) {
		var _def = panelSetDef,
			_parentNode = (typeof(_def.parentNode) == 'string') ? R8.Utils.Y.one('#'+_def.parentNode) : _def.parentNode,

			_panelHeightOffet = 0,
			_panelWidthOffset = 0,

			_panels = {},

			_initialized = false,
			_events = {};

		for(var p in _def.panels) {
			_panels[_def.panels[p].id] = new R8.UI.panel(_def.panels[p]);
		}
		return {
			init: function() {

				for(var p in _panels) {
					_panels[p].set('panelSet',this);
					_panels[p].init();
				}
				this.resize();
				_initialized = true;
			},
			resize: function() {
				var pRegion = _parentNode.get('region'),
					remainingWidth = pRegion.width,
					remainingHeight = pRegion.height;

				for(var p in _panels) {
					var width = _panels[p].get('width'),
						height = _panels[p].get('height');

					if(typeof(width) == 'string') {
						if(width == 'max') {
							var newWidth = remainingWidth;
						} else {
							var newWidth = Math.floor((parseFloat(width)/100)*pRegion.width);
						}
					} else {
						var newWidth = width;
					}
					if(typeof(height) == 'string') {
						if(width == 'max') {
							var newHeight = remainingHeight;
						} else {
							var newHeight = Math.floor((parseFloat(height)/100)*pRegion.height);
						}
					} else {
						var newHeight = height;
					}
					remainingWidth = remainingWidth - newWidth;
					ramainingHeight = remainingHeight - newHeight;
					_panels[p].set('width',newWidth);
					_panels[p].set('height',newHeight);

					_panels[p].resize();
				}
			},
			render: function() {
				for(var p in _panels) {
					_parentNode.append(_panels[p].render());
				}
			},
			get: function(key) {
				switch(key) {
					case "parentRegion":
						return _parentNode.get('region');
						break;
				}
			},
			getPanelById: function(panelId) {
				if(typeof(_panels[panelId]) != 'undefined') return _panels[panelId];

				return false;
			}
		}
	};
}

if (!R8.UI.panel) {

	R8.UI.panel = function(panelDef) {
		var _def = panelDef,
			_id = _def.id,
			_panelSet = null,

			_height = _def.height,
			_width = _def.width,

			_headerMargin = 2,
			_minWidth = _def.minWidth,
			_minHeight = _def.minHeight,
			_relativePos = _def.relativePos,
			_marginTop = 10,
			_marginRight = 5,
			_marginBottom = 5,
			_marginLeft = 5,

			_node = null,
			_headerNode = null,
			_bodyNode = null,
			_panelTpl = '',

			_initialized = false,
			_events = {};

/*
		if(typeof(_def.pClass) == 'undefined') _def.pClass = '';
		if(typeof(_def.headerClass) == 'undefined') _def.headerClass = '';
		if(typeof(_def.contentClass) == 'undefined') _def.contentClass = '';

		if(typeof(_def.views) != 'undefined') {
			for(var v in _def.views) {
				if(typeof(_def.views[v].tClass) == 'undefined') _def.views[v].tClass = '';
				if(typeof(_def.views[v].cClass) == 'undefined') _def.views[v].cClass = '';
			}
		} else {
			_def.views = [];
		}
*/

/*
//string, number
		//if string its should be a %
		if(typeof(_def.height) == 'string') {
			
		}
*/
		return {
			init: function() {
				_node = R8.Utils.Y.one('#'+_def.id+'-wrapper');
				_headerNode = R8.Utils.Y.one('#'+_def.id+'-header');
				_bodyNode = R8.Utils.Y.one('#'+_def.id+'-body');

//				this.initViews();
				_initialized = true;

//				this.resize();
//				this.loadViews();
			},
			initViews: function() {
				for(var v in _def.views) {
					var viewDef = _def.views[v];
					if(typeof(viewDef.method) == 'undefined') continue;
					_viewContentNodes[viewDef.id] = R8.Utils.Y.one('#view-content-'+viewDef.id);
				}
			},
			resize: function() {
				if(!_initialized) return;

				var adjustedHeight = _def.marginTop+_def.marginBottom;
				var adjustedWidth = _def.marginLeft + _def.marginRight;

				_node.setStyles({
					'height': _height,
					'width': _width
				});

				_node.get('children').item(0).setStyles({
					'height': _height-adjustedHeight,
					'width': _width-adjustedWidth,
					'marginTop': _def.marginTop,
					'marginRight': _def.marginRight,
					'marginBottom': _def.marginBottom,
					'marginLeft': _def.marginLeft
				});

				var pRegion  =_node.get('children').item(0).get('region');
				_bodyNode.setStyles({
					'height': pRegion.height-(_headerNode.get('region').height+_headerMargin),
					'width': pRegion.width
				});
//TODO: revisit for dashboard pass, right now only focused on height resizing

//				var bodyHeight = _node.get('region').height - _headerNode.get('region').height;
//				_bodyNode.setStyles({'height': bodyHeight-6,'width': _node.get('region').width});
/*
				var numViews = _def.views.length;
				for(var i=0; i < numViews; i++) {
					if(_def.views[i].id == _currentView && typeof(_def.views[i].resizeMethod) != 'undefined') {
						_viewContentNodes[_def.views[i].id].setStyles({'height':contentHeight,'width':_node.get('region').width,'backgroundColor':'#FFFFFF'});
						R8.IDE.views[_def.views[i].resizeMethod]();
						i = numViews + 1;
					}
				}
*/
			},
			render: function() {
//				this.setViewFocus();
//				_panelTpl = R8.Rtpl[_def.tplName]({'panel': _def});

				_panelTpl = R8.Rtpl[_def.tplName]({'panel': _def});
return _panelTpl;

				var panelNode = R8.Utils.Y.Node.create(_panelTpl);
				var adjustedHeight = _def.marginTop+_def.marginBottom;
				var adjustedWidth = _def.marginLeft + _def.marginRight;

				panelNode.setStyles({
					'height': _height,
					'width': _width
				});
				panelNode.get('children').item(0).setStyles({
					'height': _def.height-adjustedHeight,
					'width': _width-adjustedWidth,
					'marginTop': _def.marginTop,
					'marginRight': _def.marginRight,
					'marginBottom': _def.marginBottom,
					'marginLeft': _def.marginLeft
				});
				return panelNode;
			},
			get: function(key) {
				switch(key) {
					case "height":
						return _def.height;
						break;
					case "width":
						return _def.width;
						break;
				}
			},
			set: function(key,value) {
				switch(key) {
					case "panelSet":
						_panelSet = value;
						return true;
						break;
					case "width":
						_width = value;
						return true;
						break;
					case "height":
						_height = value;
						return true;
						break;
					case "headerText":
						R8.Utils.Y.one('#'+_id+'-header-text').set('innerHTML',value);
						return true;
						break;
					case "bodyContent":
						_bodyNode.set('innerHTML','');
						_bodyNode.append(value);
						return true;
						break;
				}
				return false;
			},
			setViewFocus: function() {
				var numViews = _def.views.length;
				if(typeof(_def.views) == 'undefined' || numViews == 0) return;

				if(typeof(_def.viewFocus) == 'undefined') {
					_def.views[0]['tClass'] = _def.views[0]['tClass'] + ' active';
					_currentView = _def.views[0].id;
				}

				for(var i=0; i < numViews; i++) {
					if(_def.views[i].id == _def.viewFocus) {
						_def.views[i]['tClass'] = _def.views[i]['tClass'] + ' active';
						_currentView = _def.views[i].id;
						i = numViews + 1;
					}
				}
			},
			loadViews: function() {
				for(var v in _def.views) {
					var viewDef = _def.views[v];
					if(typeof(viewDef.method) == 'undefined') continue;
					R8.IDE.views[viewDef.method](_viewContentNodes[viewDef.id]);
				}
			}
		}
	};
}