
if(!R8.Notifications) {

	(function(R8){
		R8.Notifications = function() {
			var _node = null,
				_panelNode = null,
				_panelOpen = false,
				_panelWidth = 400,

				_tbarTpl = '<div class="tbar-plugin notifications">\
							<div class="icon"></div>\
							<div id="notify-count" class="notify-count">5</div>\
						</div>';

				_panelTpl = '<div id="notifications-panel">\
								<div class="item">\
									<div class="icon warning"></div>\
									<div class="content">This is your first warning.......</div>\
								</div>\
							</div>';
			return {
				init: function(cfg) {
					_node = R8.Utils.Y.one('#'+cfg.nodeId);
					_node.on('click',function(e){
						this.toggleNotifyPanel();
						e.stopImmediatePropagation();
					},this);

					R8.Utils.Y.one('#page-container').append(_panelTpl);
					_panelNode = R8.Utils.Y.one('#notifications-panel');
					var topbarNodeId = R8.Workspace.get('topbarNodeId');
					var pTop = R8.Utils.Y.one('#'+topbarNodeId).get('region').bottom,
						pLeft = _node.get('region').right-_panelWidth;
	
					_panelNode.setStyles({'top':pTop,'left':pLeft});

					this.startPoller();
				},
				render: function() {
					return _tbarTpl;
				},
				panelOpen: function() {
					return _panelOpen;
				},
				toggleNotifyPanel: function() {
					if(_panelOpen == true) {
						_node.removeClass('active');
						_panelNode.setStyle('display','none');
						_panelOpen = false;
					} else {
						_node.addClass('active');
						_panelNode.setStyle('display','block');
						_panelOpen = true;

						var dcId = R8.Workspace.get('context_id'),
							that = this,
							notificationsCallback = function(ioId,responseObj) {
								eval("var response =" + responseObj.responseText);
								//TODO: revisit once controllers are reworked for cleaner result package
								notification_list = response['application_datacenter_get_warnings']['content'][0]['data'];
console.log(notification_list);
							}
						var params = {
							'callbacks': {
								'io:success':notificationsCallback
							}
						};
						R8.Ctrl.call('datacenter/get_warnings/'+dcId,params);
					}
				},
				tempCallback: function() {
					
				},
				startPoller: function() {
					
				},
				cancelPoller: function() {
					
				}
			}
		}();
	})(R8)
}
