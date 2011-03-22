
if(!R8.Notifications) {

	(function(R8){
		R8.Notifications = function() {
			var _node = null,
				_panelNode = null,
				_panelOpen = false,
				_panelWidth = 400,
				_notificationList = [],

				_tbarTpl = '<div class="tbar-plugin notifications">\
							<div class="icon"></div>\
							<div id="notify-count" class="notify-count"></div>\
						</div>';

				_panelTpl = '<div id="notifications-panel">\
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
						pLeft = _node.get('region').right-_panelWidth-11;
	
					_panelNode.setStyles({'top':pTop,'left':pLeft});

					this.startPoller();

					R8.Utils.Y.one('#page-container').on('click',function(e){
						if(this.panelOpen()) this.toggleNotifyPanel();
					},this);

					var itemMenter = R8.Utils.Y.delegate('mouseenter',function(e){
						var itemId = e.currentTarget.getAttribute('data-node-id');
						R8.Workspace.itemFocus(itemId);
					},'#notifications-panel','.item',this);
					var itemMleave = R8.Utils.Y.delegate('mouseleave',function(e){
						var itemId = e.currentTarget.getAttribute('data-node-id');
						R8.Workspace.blurItems();
					},'#notifications-panel','.item',this);
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
//						this.refreshList();
					}
				},
				refreshList: function() {
						var dcId = R8.Workspace.get('context_id'),
							that = this,
							notificationsCallback = function(ioId,responseObj) {
								eval("var response =" + responseObj.responseText);
								//TODO: revisit once controllers are reworked for cleaner result package
								notification_list = response['application_datacenter_get_warnings']['content'][0]['data'];
//DEBUG
console.log(notification_list);

								that.setLatestList(notification_list);
							}
						var params = {
							'callbacks': {
								'io:success':notificationsCallback
							}
						};
						R8.Ctrl.call('datacenter/get_warnings/'+dcId,params);
				},
				updateCount: function() {
					R8.Utils.Y.one('#notify-count').set('innerHTML',_notificationList.length);
				},
				setLatestList: function(nList) {
					_notificationList = nList;
					this.updateCount();
					_panelNode.set('innerHTML',R8.Rtpl.notification_list({'notification_list':nList}));
				},
				startPoller: function() {
					
				},
				cancelPoller: function() {
					
				},
				addErrors: function(errorList) {
					for(var i in errorList) {
						_notificationList.push(errorList[i]);
					}
					this.updateCount();
					_panelNode.prepend(R8.Rtpl.notification_list({'notification_list':errorList}));
console.log('inside of notifications addErrors....');
console.log(errorList);
				}
			}
		}();
	})(R8)
}
