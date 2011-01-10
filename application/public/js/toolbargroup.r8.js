
if(!R8.ToolbarGroup) {

	R8.ToolbarGroup = function(cfg) {
		var _cfg = cfg,
			_id = cfg['id'],
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

					_tools[toolId].open();

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
			render: function() {
				return _tpl;
			},
			open: function() {
				_modalContentNode = R8.Workspace.renderModal();

				this.loadContent(_modalContentNode);
			},
			loadContent: _cfg['contentLoader']
		}
	}

}
