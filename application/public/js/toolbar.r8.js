
if (!R8.Toolbar) {

//	(function(R8) {
		R8.Toolbar = function(options) {
			return {
				foo : null,
				init : function(options) {
this.foo = options.foo;
return;
					if(typeof(options['node']) == 'undefined') return false;

					this.nodeId = options['node'];
					this.toolbarId = this.nodeId+'-toolbar';
					this.toolbarBodyId = this.nodeId+'-tb-body';
					this.toolbarNode = R8.Utils.Y.one('#'+this.toolbarId);

					if(typeof(options['tools']) != 'undefined') {
						this.setupTools(options['tools']);
					}
				},

				setupTools : function(toolList) {
					for(i in toolList) {
						this.addTool(toolList[i]);
					}
//TODO: dont know why, might be rendering/timing issue, but had to make seperate loop to register events
//else, only the last tab was getting fully setup
					for (i in this.loadedTools) {
						this.registerToolEvents(i);
					}
					YUI().use('anim', function(Y){
						R8.Toolbar.toolbarAnim = new Y.Anim({
							node: '#'+R8.Toolbar.toolbarId,
							duration: 0.1,
						});
						R8.Toolbar.toolbarAnim.on('end',function(){
						});
					});

					var temp = R8.Utils.Y.delegate('mouseover',function(e){
							e.currentTarget.addClass('active');
						},'#'+this.toolbarBodyId,'.tool-button');
					var temp2 = R8.Utils.Y.delegate('mouseout',function(e){
							e.currentTarget.removeClass('active');
						},'#'+this.toolbarBodyId,'.tool-button');
					var temp3 = R8.Utils.Y.delegate('mousedown',function(e){
							e.currentTarget.setStyles({'backgroundPosition':'-22px 0px'});
						},'#'+this.toolbarBodyId,'.tool-button');
					var temp3 = R8.Utils.Y.delegate('mouseup',function(e){
							e.currentTarget.setStyles({'backgroundPosition':'0px 0px'});
						},'#'+this.toolbarBodyId,'.tool-button');
					var temp3 = R8.Utils.Y.delegate('click',function(e){
							var targetId = e.currentTarget.get('id')+'-content';
							var toolContent = R8.Utils.Y.one('#'+targetId);
							toolContent.setStyles({'left':'0px'});
							this.toolbarAnim.set('to', {
								xy: [this.toolbarNode.getX(), this.toolbarNode.getY()+30]
							});
							this.toolbarAnim.run();

						},'#'+this.toolbarBodyId,'.tool-button',this);
				},

				testAnim : function() {
					this.toolbarAnim.set('to', {
						xy: [this.toolbarNode.getX()-10, this.toolbarNode.getY()]
					});
					this.toolbarAnim.run();
				},

				addTool : function(toolId) {
					var numTools = this.loadedTools.length;
					var notFirstTool = '';
					(numTools > 0) ? notFirstTool = 'not-first' : notFirstTool = '';

					//get/load tool hear
					var tool = this.getToolDef(toolId);

					var toolHTML = '<div data-toolindex="'+numTools+'" id="'+this.nodeId+'-tool-'+tool['name']+'" class="tool-button '+notFirstTool+'">';
					toolHTML	+= 		'<div id="'+this.nodeId+'-'+tool['name']+'-tool" class="tool item-'+tool['name']+'"></div>';
					toolHTML	+= '</div>';

//					var tabHolder = document.getElementById('cmdbar-tabs');
//					tabHolder.innerHTML += tabHTML;
					var toolbarNode = R8.Utils.Y.one('#'+this.toolbarBodyId);
					toolbarNode.append(toolHTML);

					if (typeof(tool['toolContent']) != 'undefined') {
						var content = tool['toolContent']();
						var toolContent = '<div id="' + this.nodeId + '-tool-' + tool['name'] + '-content" class="toolbar-tool-content">' + content;
						toolContent += '<div id="' + this.nodeId + '-tool-' + tool['name'] + '-exit" class="tbar-exit"></div>';
						toolContent += '</div>';

						toolbarNode.append(toolContent);
						
						R8.Utils.Y.one('#' + this.nodeId + '-tool-' + tool['name'] + '-exit').on('click', function(e){

//							var targetId = e.currentTarget.get('id') + '-content';
//							var toolContent = R8.Utils.Y.one('#' + targetId);
//							toolContent.setStyles({
//								'left': '0px'
//							});

							this.toolbarAnim.set('to', {
								xy: [this.toolbarNode.getX(), this.toolbarNode.getY() - 30]
							});
							this.toolbarAnim.run();
						}, this);
					}
					var newToolIndex = numTools;
					this.loadedTools[newToolIndex] = tool;

					return newToolIndex;
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
//	})(R8);
}

var tbar1 = R8.Toolbar();
var tbar2 = R8.Toolbar();
tbar1.init({'foo':'tbar1'});
tbar2.init({'foo':'tbar2'});

console.log('tbar1.foo:'+tbar1.foo);

