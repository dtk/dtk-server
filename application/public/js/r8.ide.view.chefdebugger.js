
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

			_nodeList = [],

//DEBUG
//			_contentTpl = '<div id="'+_panel.get('id')+'-'+_view.id+'" class="target-viewspace"></div>',
			_contentTpl = '<div id="'+_panel.get('id')+'-chef-debugger-wrapper" style="">\
								<div id="'+_panel.get('id')+'-chef-debugger-header" class="view-header">\
									<select id="'+_panel.get('id')+'-chef-debugger-available-nodes" name="'+_panel.get('id')+'-chef-debugger-available-nodes"></select>\
								</div>\
								<div id="'+_panel.get('id')+'-chef-debugger-content" style="overflow-y: scroll;">\
								</div>\
						</div>',

			_contentWrapperNode = null,
			_contentNode = null,
			_headerNode = null,

			_nodeSelect = null,
			_currentNodeId = '',
			_logContents = {},

			_initialized = false,

			//FROM WORKSPACE
			_viewSpaces = {},
			_viewSpaceStack = [],
			_currentViewSpace = null,
			_viewContext = 'node',

			_cmdBar = null,

			_logPollerTimeout = null,
			_events = {};

		return {
			init: function() {
				_headerNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id+'-header');
				_contentNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id+'-content');
				_contentWrapperNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id+'-wrapper');

				_nodeSelect = document.getElementById(_panel.get('id')+'-'+_view.id+'-available-nodes');
				_nodeSelectYUI = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id+'-available-nodes');

				var that=this;
				_nodeSelect.onchange = function() {
					that.changeLogFocus(this.options[this.selectedIndex].value);
				}

				var items = R8.IDE.get('nodesInEditor');
				for(var i in items) {
					this.addNode(items[i]);
				}

				_initialized = true;
			},
			render: function() {
				return _contentTpl;
			},
			resize: function() {
				if(!_initialized) return;

				var pRegion = _panel.get('node').get('region');

				_contentWrapperNode.setStyles({'height':pRegion.height,'width':pRegion.width});
//				_contentNode.setStyles({'height':pRegion.height,'width':pRegion.width});
				_contentNode.setStyles({'height':pRegion.height-(1+_headerNode.get('region').height),'width':pRegion.width});

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

				this.startLogPoller();
			},
			blur: function() {
				_contentWrapperNode.setStyle('display','none');
//				clearTimeout(_logPollerTimeout);
				this.stopLogPoller();
			},
			close: function() {
				_contentWrapperNode.purge(true);
				_contentWrapperNode.remove();
			},

//------------------------------------------------------
//these are debugger view specific functions
//------------------------------------------------------
			startLogPoller: function() {
				var that = this;
				var fireLogPoller = function() {
					that.pollLog();
				}
				_logPollerTimeout = setTimeout(fireLogPoller,2000);
			},

			stopLogPoller: function() {
				clearTimeout(_logPollerTimeout);
				_logPollerTimeout = null;
			},
/*
				var that=this;
				var pollerCallback = function() {
					that.pollLog();
				}
				_logPollerTimeout = setTimeout(pollerCallback,3000);
*/
			changeLogFocus: function(nodeId) {
				_currentNodeId = nodeId;

				_contentNode.set('innerHTML','');

				if(typeof(_logContents[nodeId]) != 'undefined') {
					this.renderLogContents(nodeId);
				}

				if(_logPollerTimeout == null && (typeof(_logContents[nodeId]) == 'undefined' || _logContents[nodeId].complete != true)) {
					this.startLogPoller();
				}
			},
			pollLog: function() {
				var that=this;
				var fireLogPoller = function() {
					that.pollLog();
				}
				_logPollerTimeout = setTimeout(fireLogPoller,2500);

				if(_currentNodeId == '') return;

				var setLogsCallback = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
					var logContent = response.application_task_get_logs.content[0].data;

					that.setLogContent(logContent);
//					contentNode.set('innerHTML',log_content);
//					contentNode.append(log_content);
				}
				var params = {
					'cfg': {
						'data': 'node_id='+_currentNodeId
					},
					'callbacks': {
						'io:success': setLogsCallback
					}
				};
				R8.Ctrl.call('task/get_logs',params);
//				R8.Ctrl.call('task/get_logs/'+level,params);
			},
			setLogContent: function(logContent) {
				for(var l in logContent) {
					_logContents[l] = logContent[l];
				}

				this.renderLogContents(_currentNodeId);

				if(_logContents[_currentNodeId].complete == true) this.stopLogPoller();
/*
      {:type=>:error,
      :error_file_ref=>
       {:type=>:recipe, :cookbook=>"java_webapp", :file_name=>"default.rb"},
       :error_type=>:error_recipe,
      :error_line_num=>2,
      :error_lines=>[],
      :error_detail=>"syntax error, unexpected tEQQ, expecting $end"}],

 */
			},
			addNode: function(nodeObj) {
				_nodeList.push(nodeObj);

				var newOptionStr = '<option value="'+nodeObj.id+'">'+nodeObj.display_name+'</option>';
				_nodeSelectYUI.append(newOptionStr);
//DEBUG
//console.log(nodeObj);
			},
			renderLogContents: function(nodeId) {
				for(var i in _logContents[_currentNodeId]['log_segments']) {
					var logSegment = _logContents[_currentNodeId]['log_segments'][i];

					switch(logSegment.type) {
						case "debug":
						case "info":
							var logTpl = '<div style="width: 100%; height: 17px; white-space: nowrap>'+logSegment.line+'</div>';
							break;
						case "error":
							var logTpl = '<div style="color: red; width: 100%; height: 17px; white-space: nowrap">'+logSegment.error_detail+'\ in file <a href="">'+logSegment.error_file_ref.file_name+'</a></div>';
							break;
					}

					_contentNode.prepend(logTpl);
				}
			},
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