
if (!R8.Toolbar) {

	R8.Toolbar = function(toolbarDef) {

		var _parentNodeId = toolbarDef['parent_node_id'],
			_parentWrapperId = _parentNodeId+'-toolbar-wrapper',
			_parentWrapperNode = R8.Utils.Y.one('#'+_parentWrapperId),

			_parentBodyId = _parentNodeId+'-large-main-body-content',
			_parentBodyNode = R8.Utils.Y.one('#'+_parentBodyId),

			_bodyId = _parentNodeId+'-tb-body',
			_bodyNode = null,
			_toolbarNodeId = _parentNodeId+'-toolbar',
			_toolbarNode = null,

			_toolList = toolbarDef['tools'],
			_loadedTools = {},
			_activeToolContentId = null,

			_toolbarAnim = null,
			_parentBodyAnim = null;

		return {

			init : function() {
				_parentWrapperNode.set('innerHTML',this.render());
				this.setToolbarNode();
				return;
			},

			setToolbarNode: function() {
				_toolbarNode = R8.Utils.Y.one('#'+_toolbarNodeId);

				if(_toolbarNode == null) {
					var that = this;
					var selfCalling = function() {
						that.setToolbarNode();
					}
					setTimeout(selfCalling,50);
					return;
				}

				_bodyNode = R8.Utils.Y.one('#'+_bodyId);
				this.setupTools();
			},

			render: function() {
				var contents = '<div id="'+_parentNodeId+'-toolbar" class="item-toolbar">\
									<div id="'+_parentNodeId+'-toolbar-main" class="item-toolbar-main">\
										<div class="tb-l-cap"></div>\
										<div id="'+_parentNodeId+'-tb-body" class="tb-body">\
										</div>\
										<div class="tb-r-cap"></div>\
									</div>\
								</div>';
				return contents;
			},

			setupTools : function() {
				for(i in _toolList) {
					this.addTool(_toolList[i]);
				}

//TODO: dont know why, might be rendering/timing issue, but had to make seperate loop to register events
//else, only the last tab was getting fully setup
//				for (i in _loadedTools) {
//					this.registerToolEvents(i);
//				}

				YUI().use('anim', function(Y){
					_toolbarAnim = new Y.Anim({
						node: '#'+_toolbarNodeId,
//						node: '#'+_parentNodeId,
						duration: 0.1
					});
					_toolbarAnim.on('end',function(e){
//						var toolbarId = e.currentTarget.get('node').get('id');
					});
					_parentBodyAnim = new Y.Anim({
						node: '#'+_parentBodyId,
						duration: 0.1
					});
					_parentBodyAnim.on('end',function(e){
					});
				});

				R8.Utils.Y.delegate('mouseover',function(e){
						e.currentTarget.addClass('active');
					},'#'+_bodyId,'.tool-button');
				R8.Utils.Y.delegate('mouseout',function(e){
						e.currentTarget.removeClass('active');
					},'#'+_bodyId,'.tool-button');
				R8.Utils.Y.delegate('mousedown',function(e){
						e.currentTarget.setStyles({'backgroundPosition':'-22px 0px'});
					},'#'+_bodyId,'.tool-button');
				R8.Utils.Y.delegate('mouseup',function(e){
						e.currentTarget.setStyles({'backgroundPosition':'0px 0px'});
					},'#'+_bodyId,'.tool-button');
				R8.Utils.Y.delegate('click',function(e){
						var targetId = e.currentTarget.get('id')+'-content',
							_activeToolContentId = targetId,
							toolId = e.currentTarget.get('id').replace(_parentNodeId+'-tool-',''),
							toolContent = R8.Utils.Y.one('#'+_activeToolContentId);

						_loadedTools[toolId].toolFocus();

						toolContent.setStyles({'left':'0px'});
						_toolbarAnim.set('to', {
							xy: [_toolbarNode.getX(), _toolbarNode.getY()+30]
						});
						_toolbarAnim.run();

						_parentBodyAnim.set('to', {
							xy: [_parentBodyNode.getX(), _parentBodyNode.getY()+90]
						});
						_parentBodyAnim.run();

					},'#'+_bodyId,'.tool-button',this);

				return;
			},

			testAnim : function() {
				_toolbarAnim.set('to', {
					xy: [_toolbarNode.getX(), _toolbarNode.getY()+30]
				});
				_toolbarAnim.run();
			},

			addTool : function(toolId) {
				var numTools = _loadedTools.length,
					notFirstTool = '';

				_loadedTools[toolId] = new AvailableTools[toolId]({'parent_id':_parentNodeId});

				(numTools > 0) ? notFirstTool = 'not-first' : notFirstTool = '';

				var toolHTML = '<div data-toolindex="'+numTools+'" id="'+_parentNodeId+'-tool-'+toolId+'" class="tool-button '+notFirstTool+'">\
							 		<div id="'+_parentNodeId+'-'+toolId+'-tool" class="tool item-'+toolId+'"></div>\
								</div>';

				_bodyNode.append(toolHTML);

				var content = _loadedTools[toolId].renderToolContent();
				var toolContent = '<div id="'+_parentNodeId+ '-tool-' + toolId + '-content" class="toolbar-tool-content">' + content + '\
									<div id="'+_parentNodeId+'-tool-' + toolId + '-exit" class="tbar-exit"></div>\
								</div>';
				_toolbarNode.append(toolContent);
				_parentBodyNode.append(_loadedTools[toolId].renderToolBodyContent());

				R8.Utils.Y.one('#' + _parentNodeId + '-tool-' + toolId + '-exit').on('click', function(e){
//				var contentNode = e.currentTarget.get('parentNode');

					_toolbarAnim.set('to', {
						xy: [_toolbarNode.getX(), _toolbarNode.getY() - 30]
					});
					_toolbarAnim.run();

					_parentBodyAnim.set('to', {
						xy: [_parentBodyNode.getX(), _parentBodyNode.getY() - 90]
					});
					_parentBodyAnim.run();

//					contentNode.setStyles({
//						'left': '-256px'
//					});
				},this);

				_loadedTools[toolId].init();
			},

			registerToolEvents : function(tIndex) {
			},

			tempDefs : {
				'quicksearch' : {
					'name':'quicksearch',
					'toolContent' : function() {
						var content = '<input name="quicksearch" type="text" size="30"/>';
						return content;
					},
					'focus':function() {
						
					},
					'blur':function() {
						
					}
				}
			}
		}
	};
	var AvailableTools = {};
}
