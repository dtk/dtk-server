
if(!R8.ToolbarGroup2) {

	R8.ToolbarGroup2 = function(cfg) {
		var _cfg = cfg,
//			_id = cfg['id'],
			_id = 'main-toolbar-group',
			_listNode = null,
			_height = null,
			_tpl = '<div id="'+_id+'" class="toolbar-group">\
						<div class="lft-endcap"></div>\
							<ul id="'+_id+'-tool-list" class="tool-list">\
							</ul>\
						<div class="rt-endcap"></div>\
					</div>',

			_events = {},
			_tools = {},
			_numTools = 0;

		return {
			init: function() {
				_listNode = R8.Utils.Y.one('#'+_id+'-tool-list');

				for(var i in _cfg.tools) {
					var toolId = _cfg.tools[i]['id'];
					_cfg['tools'][i]['listNode'] = _listNode;
					_tools[toolId] = new R8.Tool(_cfg.tools[i]);
					_listNode.append(_tools[toolId].render());
					_tools[toolId].init();
					_numTools++;
				}

				_events['toolClick'] = R8.Utils.Y.delegate('click',function(e){
					var toolNodeId = e.currentTarget.get('id');
					var toolId = toolNodeId.replace('-tool','');

					if(_tools[toolId].get('type') == 'modal') {
						_tools[toolId].open();
					} else if(_tools[toolId].get('type') == 'exe') {
						_tools[toolId].exec();
					}

				},_listNode,'.tool-item');
			},
			render: function() {
				return _tpl;
			}
		}
	}

	R8.Tool = function(cfg) {
		var _cfg = cfg,
			_id = cfg['id'],
			_i18n = cfg['i18n'],
			_listNode = cfg.listNode,
			_tpl = '<li title="'+_i18n+'" id="'+_id+'-tool" class="tool-item first">\
							<div class="btn-bg">\
								<div class="tool-btn '+_id+'"></div>\
							</div>\
					</li>',
			_modalContentNode = null;

		return {
			init: function() {
				
			},
			get: function(key) {
				switch(key) {
					case "type":
						return _cfg['type'];
						break;
				}
			},
			render: function() {
				return _tpl;
			},
			open: function() {
				_modalContentNode = R8.IDE.renderModal();
				var result = this.loadContent(_modalContentNode);
//				if(!result) R8.IDE.destroyShim();
			},
			exec: function() {
				_cfg['execCallback']();
			},
			loadContent: _cfg['contentLoader']
		}
	}

}
