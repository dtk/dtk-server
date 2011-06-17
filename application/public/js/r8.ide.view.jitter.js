
if (!R8.IDE.View.jitter) {

	R8.IDE.View.jitter = function(view) {
		var _view = view,
			_id = _view.id,
			_panel = _view.panel,
			_pendingDelete = {},

			_modalNoe = null,
			_modalNodeId = 'jitter-'+_id+'-modal',
			_shimNodeId = null,
			_shimNode = null,

			_alertNode = null,
			_alertNodeId = null,

			_nodeList = [],

//DEBUG
//TODO: update the css from target-viewspace
//			_contentTpl = '<div id="'+_panel.get('id')+'-'+_view.id+'" class="target-viewspace"></div>',
			_contentTpl = '<div id="'+_panel.get('id')+'-'+_id+'-wrapper" style="">\
								<div id="'+_panel.get('id')+'-'+_id+'-header" class="view-header">\
								</div>\
								<div id="'+_panel.get('id')+'-'+_id+'-content" style="overflow-y: scroll;">\
								</div>\
						</div>',

			_contentWrapperNode = null,
			_contentNode = null,
			_headerNode = null,

			_nodeSelect = null,
			_currentNodeId = '',
			_jitContents = {},

			_initialized = false,

			//FROM WORKSPACE
			_viewSpaces = {},
			_viewSpaceStack = [],
			_currentViewSpace = null,
			_viewContext = 'node',

			_cmdBar = null,

			_jitPollerTimeout = null,
			_events = {};

		return {
			init: function() {
				_headerNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id+'-header');
				_contentNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id+'-content');
				_contentWrapperNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id+'-wrapper');

				_nodeSelect = document.getElementById(_panel.get('id')+'-'+_view.id+'-available-nodes');
				_nodeSelectYUI = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id+'-available-nodes');

				this.startJitPoller();

				_initialized = true;
			},
			render: function() {
				return _contentTpl;
			},
			resize: function() {
				if(!_initialized) return;

				var pRegion = _panel.get('node').get('region');

				_contentWrapperNode.setStyles({'height':pRegion.height-6,'width':pRegion.width-6});
//				_contentNode.setStyles({'height':pRegion.height,'width':pRegion.width});
				_contentNode.setStyles({'height':pRegion.height-(6+1+_headerNode.get('region').height),'width':pRegion.width-6});

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
//these are debugger view specific functions
//------------------------------------------------------
			startJitPoller: function() {
				var that = this;
				var fireJitPoller = function() {
console.log('inside of setTimeout function to start poller...');
					that.getCompilation();
				}
//DEBUG
console.log('should be starting jit poller...');
				_jitPollerTimeout = setTimeout(fireJitPoller,2000);
			},

			stopJitPoller: function() {
				clearTimeout(_jitPollerTimeout);
				_jitPollerTimeout = null;
			},
/*
				var that=this;
				var pollerCallback = function() {
					that.getCompilation();
				}
				_jitPollerTimeout = setTimeout(pollerCallback,3000);
*/
			getCompilation: function() {
console.log('at top of getCompilation func....');
				var that=this;
/*
				var fireJitPoller = function() {
					that.getCompilation();
				}
				_jitPollerTimeout = setTimeout(fireJitPoller,5000);

*/
//				if(_currentNodeId == '') return;

				var targetView = R8.IDE.get('currentEditorView');
				if(targetView == null || targetView.get('type') != 'target') return;

				var targetId = targetView.get('id');
				var	that = this;
				var	getJitCallback = function(ioId,responseObj) {
						eval("var response =" + responseObj.responseText);
						//TODO: revisit once controllers are reworked for cleaner result package
						var jitContent = response['application_datacenter_get_warnings']['content'][0]['data'];
//console.log(jitContent);
//return;
						that.setJitContent(jitContent);
					}
				var params = {
					'callbacks': {
						'io:success':getJitCallback
					}
				};
				R8.Ctrl.call('datacenter/get_warnings/'+targetId,params);
			},
			setJitContent: function(jitContent) {
				var nWrapperNode = R8.Utils.Y.Node.create('<div id="jitter-panel"></div>');
				_contentNode.set('innerHTML','');
				_contentNode.append(nWrapperNode.append(R8.Rtpl.notification_list_ide({'notification_list':jitContent})));

//				this.renderJitContents(_currentNodeId);

//				if(_jitContents[_currentNodeId].complete == true) this.stopLogPoller();
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
			updateNodeName: function(nodeId,nodeName) {
				var numNodes = _nodeSelect.options.length;
				for(var i=0; i < numNodes; i++) {
					if(_nodeSelect.options[i].value==nodeId) {
						_nodeSelect.options[i].text = nodeName;
					}
				}
			},
			renderLogContents: function(nodeId) {
				for(var i in _jitContents[_currentNodeId]['log_segments']) {
					var logSegment = _jitContents[_currentNodeId]['log_segments'][i];

					switch(logSegment.type) {
						case "debug":
						case "info":
							var logTpl = '<div style="width: 100%; height: 17px; white-space: nowrap>'+logSegment.line+'</div>';
							break;
						case "error":
							if(typeof(logSegment.error_file_ref) == 'undefined' || logSegment.error_file_ref == null || logSegment.error_file_ref == '') {
								var logTpl = '<div style="color: red; width: 100%; height: 17px; white-space: nowrap">'+logSegment.error_detail+'</div>';
							} else {
								var logTpl = '<div style="color: red; width: 100%; height: 17px; white-space: nowrap">'+logSegment.error_detail+' in file <a href="">'+logSegment.error_file_ref.file_name+'</a></div>';
							}

							break;
					}

					_contentNode.append(logTpl);
				}
				var contentDiv = document.getElementById(_contentNode.get('id'));
				contentDiv.scrollTop = 5000;
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