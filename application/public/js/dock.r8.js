
if(!R8.Workspace.Dock) {

	(function(R8){

	R8.Workspace.Dock = function() {
		var _nodeId = 'wspace-dock',
			_node = null,
			_display = 'none',
			_state = 'foo',
			_right = '0',
			_top = '0';

		return {
			init: function(options) {
				_display = (!options['display']) ? 'none' : options['display'];
				_top = (!options['top']) ? '0' : options['top'];
				_right = (!options['right']) ? '0' : options['right'];
			},

			render: function() {
				var content = '<div id="'+_nodeId+'" style="display: '+_display+'; position: absolute; height: 400px; width: 250px; border: 3px solid #CCCCCC; background-color: #DDDDDD; right: '+_right+'px; top: '+_top+'px;">\
						<div id="wspace-dock-topbar" style="float: left; position: relative; height: 30px; width: 100%; background-color: #FFFFFF;">\
							<div id="wspace-dock-close" class="close-tab-temp"></div>\
						</div>\
						<div id="wspace-dock-body" style="overflow-x: hidden; overflow-y: scroll; position: relative; float: left; height: 360px; width: 240px;">\
						</div>\
					</div>';

				return content;
			},

			show: function() {
				if(_node == null) _node = R8.Utils.Y.one('#'+_nodeId);

				_node.setStyle('display','block');
			},
			hide: function() {
				if(_node == null) _node = R8.Utils.Y.one('#'+_nodeId);

				_node.setStyle('display','none');
			},

			panelSubmit: function(formId) {
				var form = document.getElementById(formId),
					route = form.route.value,
					cfg = {
						form: {
							id: formId,
							useDisabled: true
						}
					};
				R8.Ctrl.call(route,'',{},cfg);
			},

			saveAttributes: function(formId) {
				var form = document.getElementById(formId),
					route = form.save_route.value,
					cfg = {
						form: {
							id: formId,
							useDisabled: true
						}
					};
				R8.Ctrl.call(route,'',{},cfg);
			},

		}		
	}();

	})(R8)
}
