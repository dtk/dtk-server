
if (!R8.Toolbar) {

	R8.Toolbar = function(toolbarDef) {

		var _parentNodeId = toolbarDef['parent_node_id'],
			_parentWrapperId = _parentNodeId+'-toolbar-wrapper',
			_parentWrapperNode = R8.Utils.Y.one('#'+_parentWrapperId),
			_bodyId = _parentNodeId+'-tb-body',
			_bodyNode = null,
			_toolbarNodeId = _parentNodeId+'-toolbar',
			_toolbarNode = null,

			_toolList = toolbarDef['tools'],
			_loadedTools = [],

			_toolBarAnim = null;

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
console.log('test:'+_toolbarNodeId);
					_toolbarAnim = new Y.Anim({
						node: '#'+_toolbarNodeId,
						duration: 0.8
					});
					_toolbarAnim.on('end',function(){
console.log('ending animation event...');
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
							toolContent = R8.Utils.Y.one('#'+targetId);

						toolContent.setStyles({'left':'0px'});
this.testAnim();
return;
						_toolbarAnim.set('to', {
							xy: [_toolbarNode.getX(), _toolbarNode.getY()+30]
						});
						_toolbarAnim.run();

					},'#'+_bodyId,'.tool-button',this);

				return;
			},

			testAnim : function() {
console.log('run test anim...');
				_toolbarAnim.set('to', {
					xy: [_toolbarNode.getX()+300, _toolbarNode.getY()]
				});
				_toolbarAnim.run();
			},

			addTool : function(toolId) {
				var numTools = _loadedTools.length,
					notFirstTool = '',
					toolDef = this.tempDefs[toolId];

				(numTools > 0) ? notFirstTool = 'not-first' : notFirstTool = '';

				var toolHTML = '<div data-toolindex="'+numTools+'" id="'+_parentNodeId+'-tool-'+toolDef['name']+'" class="tool-button '+notFirstTool+'">\
							 		<div id="'+_parentNodeId+'-'+toolDef['name']+'-tool" class="tool item-'+toolDef['name']+'"></div>\
								</div>';

				_bodyNode.append(toolHTML);

				if (typeof(toolDef['toolContent']) != 'undefined') {
					var content = toolDef['toolContent']();
					var toolContent = '<div id="'+_parentNodeId+ '-tool-' + toolDef['name'] + '-content" class="toolbar-tool-content">' + content + '\
										<div id="'+_parentNodeId+'-tool-' + toolDef['name'] + '-exit" class="tbar-exit"></div>\
									</div>';

					_toolbarNode.append(toolContent);

					R8.Utils.Y.one('#' + _parentNodeId + '-tool-' + toolDef['name'] + '-exit').on('click', function(e){
						var targetId = e.currentTarget.get('id') + '-content',
							toolContent = R8.Utils.Y.one('#' + targetId);

//						toolContent.setStyles({
//							'left': '-256px'
//						});

						_toolbarAnim.set('to', {
							xy: [_toolbarNode.getX(), _toolbarNode.getY() - 30]
						});
						_toolbarAnim.run();
					},this);

				}

				var newToolIndex = numTools;
				_loadedTools[newToolIndex] = toolDef;
			},

			getToolDef : function(toolId) {
				return this.tempDefs[toolId];
			},

			registerToolEvents : function(tIndex) {
			},

			nodeId : null,

			toolbarId : null,
			toolbarNode : null,

			toolbarBodyId : null,

			loadedTools : [],

			toolbarAnim : null,

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
}
