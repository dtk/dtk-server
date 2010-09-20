 
if (!R8.Cmdbar) {

	(function(R8) {
		R8.Cmdbar = function(options) {
			return {
				init : function() {
					this.setupTabs();
					this.setupCmdLine();
				},

				setupTabs : function() {
					for(i in this.tabs) {
						this.addTab(this.tabs[i]);
					}
//TODO: dont know why, might be rendering/timing issue, but had to make seperate loop to register events
//else, only the last tab was getting fully setup
					for (i in this.loadedTabs) {
						R8.Cmdbar.registerTabEvents(i);
					}
				},

				addTab : function(tab) {
					var numTabs = this.loadedTabs.length;
					var zIndex = 510 - numTabs;
					var notFirstTab = '';
					(numTabs > 0) ? notFirstTab = 'not-first' : notFirstTab = '';

					var tabHTML = '<div data-tabindex="'+numTabs+'" id="cmdbar-'+tab['name']+'-tab" class="tab '+tab['status']+' '+notFirstTab+'" style="z-index: '+zIndex+';">';
					tabHTML	+=	'<div class="lcap"></div>';
					tabHTML	+= '<div class="body">'+tab['i18n']+'</div>';
					tabHTML	+= '<div class="rcap">';
					tabHTML	+= '<div data-tabindex="'+numTabs+'" id="cmdbar-'+tab['name']+'-tab-close" class="close-tab"></div>';
					tabHTML	+= '</div></div>';

//					var tabHolder = document.getElementById('cmdbar-tabs');
//					tabHolder.innerHTML += tabHTML;
					R8.Utils.Y.one('#cmdbar-tabs').append(tabHTML);


//					var tabContainer = document.getElementById('cmdbar-tab-content-wrapper');
//					var tabContentsHTML = '<div id="cmdbar-'+tab['name']+'-tab-content" style="height: 300px; width: 100%"></div>';
					if (typeof(tab['contentCallback']) === 'undefined') {
						var tabContentsHTML = '<div id="cmdbar-' + tab['name'] + '-tab-content" style="height: 100px; width: 100%; display:none;"></div>';
						R8.Utils.Y.one('#cmdbar-tab-content-wrapper').append(tabContentsHTML);
//						tabContainer.innerHTML += tabContentsHTML;
					} else {
						tab['contentCallback']();
					}
					var newTabIndex = numTabs;
//					this.loadedTabs[newTabIndex] = R8.Cmdbar.cloneTabObj(tab);
					this.loadedTabs[newTabIndex] = tab;

//					this.loadedTabs[newTabIndex]['contentElem'] = R8.Utils.Y.one('#cmdbar-'+R8.Cmdbar.loadedTabs[newTabIndex]['name']+'-tab-content');
					if(typeof(this.loadedTabs[newTabIndex]['contentLoader']) !='undefined') {
						this.loadedTabs[newTabIndex]['contentLoader']();
					}
//					this.loadedTabs[newTabIndex]['node'] = R8.Utils.Y.one('#cmdbar-'+R8.Cmdbar.loadedTabs[newTabIndex]['name']+'-tab');

					return newTabIndex;
				},

				cloneTabObj : function(o) {
					if(typeof(o) != 'object') return o;
					if(o == null) return o;

					var newO = new Object();

					for(var i in o) newO[i] = R8.Cmdbar.cloneTabObj(o[i]);
					return newO;
				},

				registerTabEvents : function(i) {
//console.log('Going to register events for tab:'+R8.Cmdbar.loadedTabs[i]['name']);
//console.log('Index is:'+i);
					YUI().use('node','event',function(Y){
						//process the tab element and related events
//						R8.Cmdbar.loadedTabs[i]['node'] = Y.one('#cmdbar-'+R8.Cmdbar.loadedTabs[i]['name']+'-tab');
						R8.Cmdbar.loadedTabs[i]['contentElem'] = Y.one('#cmdbar-'+R8.Cmdbar.loadedTabs[i]['name']+'-tab-content');
						R8.Cmdbar.loadedTabs[i]['node'] = Y.one('#cmdbar-'+R8.Cmdbar.loadedTabs[i]['name']+'-tab');

						R8.Cmdbar.loadedTabs[i]['events']['tabClick'] = R8.Cmdbar.loadedTabs[i]['node'].on('click',function(e){
							e.halt();
							R8.Cmdbar.changeTabFocus(e.currentTarget.getAttribute('data-tabindex'));
						});

						//process the close region element and related events
						R8.Cmdbar.loadedTabs[i]['closeElem'] = Y.one('#cmdbar-'+R8.Cmdbar.loadedTabs[i]['name']+'-tab-close');
//console.log('Close Elem...');
//console.log(R8.Cmdbar.loadedTabs[i]['closeElem']);
						R8.Cmdbar.loadedTabs[i]['events']['closeMoEvent'] = R8.Cmdbar.loadedTabs[i]['closeElem'].on('mouseover', function(e){
							e.halt();
							e.currentTarget.addClass('hover');
						});
						R8.Cmdbar.loadedTabs[i]['events']['closeMlEvent'] = R8.Cmdbar.loadedTabs[i]['closeElem'].on('mouseleave', function(e){
							e.halt();
							e.currentTarget.removeClass('hover');
						});
						R8.Cmdbar.loadedTabs[i]['events']['closeClickEvent'] = R8.Cmdbar.loadedTabs[i]['closeElem'].on('click', function(e){ 
							e.halt();
							var tabIndex = e.currentTarget.getAttribute('data-tabindex');
							var tabName = R8.Cmdbar.loadedTabs[tabIndex]['name'];
							var tabContainerElem = document.getElementById('cmdbar-tab-content-wrapper');
							var tabContentElem = document.getElementById('cmdbar-'+tabName+'-tab-content');
							tabContainerElem.removeChild(tabContentElem);

							var cmdbarTabsElem = document.getElementById('cmdbar-tabs');
							var tabElem = document.getElementById('cmdbar-'+tabName+'-tab');
							cmdbarTabsElem.removeChild(tabElem);

							//clean up all event handlers
							for(event in R8.Cmdbar.loadedTabs[tabIndex]['events']) {
								R8.Cmdbar.loadedTabs[tabIndex]['events'][event].detach();
								delete(R8.Cmdbar.loadedTabs[tabIndex]['events'][event]);
							}
							R8.Cmdbar.loadedTabs[tabIndex]['deleteCleanup']();
							R8.Cmdbar.deleteTabs(tabIndex);
							if(R8.Cmdbar.loadedTabs.length == 1) {
								R8.Cmdbar.changeTabFocus(0);
							}
						});
					});
				},

				changeTabFocus : function(index) {
					var zIndex = 509;

					for(tab in R8.Cmdbar.loadedTabs) {
						if(tab == index) {
							R8.Cmdbar.loadedTabs[tab]['node'].addClass('active');
							R8.Cmdbar.loadedTabs[tab]['node'].setStyles({'zIndex': 510});
							R8.Cmdbar.loadedTabs[tab]['status'] = 'active';
							R8.Cmdbar.loadedTabs[tab]['contentElem'].setStyle('display','block');

							if(R8.Cmdbar.loadedTabs.length == 1)
								R8.Cmdbar.loadedTabs[tab]['node'].removeClass('not-first');

							R8.Cmdbar.loadedTabs[tab].focus();
						} else {
							R8.Cmdbar.loadedTabs[tab]['node'].removeClass('active');
							R8.Cmdbar.loadedTabs[tab]['status'] = '';
							R8.Cmdbar.loadedTabs[tab]['node'].setStyles({'zIndex': zIndex});
//							R8.Cmdbar.loadedTabs[tab]['contentElem'].setStyle('display','none');
							zIndex--;
							R8.Cmdbar.loadedTabs[tab].blur();
						}
					}
				},

				toggleTabs : function() {
					R8.Utils.$("#cmdbar-tab-content-wrapper").slideToggle(200);
					if(R8.Cmdbar.tabsPaneOpen) R8.Cmdbar.tabsPaneOpen = false;
					else R8.Cmdbar.tabsPaneOpen = true;
/*
					var tabs_display = document.getElementById('cmdbar-tab-content-wrapper').style.display;
					if(tabs_display.toLowerCase() == 'block') R8.Cmdbar.tabsPaneOpen = true;
					else R8.Cmdbar.tabsPaneOpen = false;
*/
				},

				isTabFocused : function(index) {
					index = parseInt(index);
					if(R8.Cmdbar.loadedTabs[index]['status'] == 'active') return true;
					else return false;
				},

				/*
				 * 	Remove the second tab
				 *	   deleteTabs(1);
				 *  Remove the second-to-last item from the array
				 *     deleteTabs(-2);
				 *  Remove the second and third items from the array
				 *     deleteTabs(1,2);
				 *  Remove the last and second-to-last items from the array
				 *     deleteTabs(-2,-1);
				*/
				deleteTabs : function(from,to) {
					from = parseInt(from);
					to = parseInt(to);

					var rest = R8.Cmdbar.loadedTabs.slice((to || from) + 1 || R8.Cmdbar.loadedTabs.length);
					R8.Cmdbar.loadedTabs.length = from < 0 ? R8.Cmdbar.loadedTabs.length + from : from;
					R8.Cmdbar.loadedTabs.push.apply(R8.Cmdbar.loadedTabs, rest);
					R8.Cmdbar.updateTabIndexes();

					if(R8.Cmdbar.loadedTabs.length == 0 && R8.Cmdbar.tabsPaneOpen) R8.Cmdbar.toggleTabs();
				},

				updateTabIndexes : function() {
					for(i in R8.Cmdbar.loadedTabs) {
						var tabName = R8.Cmdbar.loadedTabs[i]['name'];
						var tabElem = R8.Utils.Y.one('#cmdbar-'+tabName+'-tab');
						tabElem.setAttribute('data-tabindex',i);
						var tabCloseElem = R8.Utils.Y.one('#cmdbar-'+tabName+'-tab-close');
						tabCloseElem.setAttribute('data-tabindex',i);
					}
				},

				setupCmdLine : function() {
					this.cmdr['node'] = R8.Utils.Y.one('#cmd');
					YUI().use('node','event',function(Y){
						R8.Cmdbar['cmdr']['events']['arrowUp'] = R8.Cmdbar['cmdr']['node'].on('keypress',function(e){

							//arrow up
							if(e.charCode == 38) {
								e.halt();
								var index = R8.Cmdbar.cmdr['qIndex'];
								if (index == 0) {
									R8.Cmdbar.cmdr['qIndex'] = 0;
									var prevCmd = R8.Cmdbar.cmdr['queue'][0]['cmd'];
									R8.Cmdbar.cmdr['node'].set('value',prevCmd);
									return;
								}

								var prevCmd = R8.Cmdbar.cmdr['queue'][index]['cmd'];
								R8.Cmdbar.cmdr['node'].set('value',prevCmd);
								R8.Cmdbar.cmdr['qIndex'] = (index-1);
							}
							//arrow down
							else if(e.charCode == 40) {
								e.halt();
								var index = R8.Cmdbar.cmdr['qIndex'];
								var qMax = R8.Cmdbar.cmdr['queue'].length-1;
								if (index == qMax) {
									R8.Cmdbar.cmdr['qIndex'] = qMax;
									R8.Cmdbar.cmdr['node'].set('value','');
									return;
								}
								var nextIndex = index+1;
								R8.Cmdbar.cmdr['qIndex'] = nextIndex;

								var nextCmd = R8.Cmdbar.cmdr['queue'][nextIndex]['cmd'];
								R8.Cmdbar.cmdr['node'].set('value',nextCmd);
							}
						}); 
					});
				},

				submit : function() {
					var cmdStr = this.cmdr['node'].get('value');
					var cmd = {
						'cmd':cmdStr,
						'status':'pending',
						'parsedCmd': cmdStr.split(' '),
					}
					this.cmdr['queue'].push(cmd);
					this.cmdr['node'].set('value', '');

					var curIndex = this.cmdr['queue'].length-1;
					this.cmdr['qIndex'] = curIndex;

					var cmdAction = this.cmdr['queue'][curIndex]['parsedCmd'][0];

					if(typeof(this.cmdHandlers[cmdAction]) == 'undefined') {
						alert(cmdAction+' is not a valid command, please try again or type cmd list for list of available commands');
					} else {
						var cmdList = [];
						var cmdLength = this.cmdr['queue'][curIndex]['parsedCmd'].length;
						for(i=1;i<cmdLength;i++) {
							if(this.cmdr['queue'][curIndex]['parsedCmd'][i] == ' ') continue;
							cmdList.push(this.cmdr['queue'][curIndex]['parsedCmd'][i]);
						}
						this.cmdHandlers[cmdAction].cmdSubmit(cmdList);
					}
//DEBUG
return;
/*
					R8.Cmdbar.changeTabFocus(1);
					R8.MainToolbar.clearSlider();
					var queryTerm = '';
					var callbacks = {
						'io:start':R8.MainToolbar.startSearch(),
						'io:end':R8.MainToolbar.endSearch(),
						'io:renderComplete':R8.MainToolbar.initSlider(),
					};
					R8.Ctrl.call('workspace/search',queryTerm,callbacks);
*/
				},

				cmdr : {
					'node' : null,
					'queue' : [],
					'qIndex' : 0,
					'events': {},
				},

				tabExists : function(tabName) {
					for(i in R8.Cmdbar.loadedTabs) {
						if(R8.Cmdbar.loadedTabs[i]['name'] == tabName) return true;
					}
					return false;					
				},

				getTabIndexByName : function(tabName) {
					for(i in R8.Cmdbar.loadedTabs) {
						if(R8.Cmdbar.loadedTabs[i]['name'] == tabName) return i;
					}
					return false;					
				},

				tabsPaneOpen : false,

//TODO: event though default, still make pluggable after fully implementing
				tabs : [],
/*
				tabs : [
					{
						'name':'output',
						'i18n':'Cmd Output',
						'status':'active',
						'node':null,
						'events':{},
//						'closeElem':null,
//						'closeMoEvent':null,
//						'closeMlEvent':null,
//						'closeClickEvent':null,
					},
					{
						'name':'node',
						'i18n':'Nodes',
						'status':'',
						'node':null,
						'events':{},
						'contentLoader': function(){
								var contentFraming = '<div class="slider-top"></div>';
								contentFraming += '<div id="sliderwrapper">';
								contentFraming += '<div id="lbutton"></div>';
								contentFraming += '<div id="slidecontainer">';
								contentFraming += '<div id="slider"></div>';
								contentFraming += '</div>';
								contentFraming += '<div id="rbutton"></div>';
								contentFraming += '</div>';
								contentFraming += '<div class="slider-btm"></div>';
								this.contentElem.set('innerHTML',contentFraming);
						},
						'tabFocusCallback': function() {
								console.log('Just got focus on the node tab....');
						},
					},
					{
						'name':'component',
						'i18n':'Components',
						'status':'',
						'node':null,
						'events':{},
						'contentLoader': function(){
								var contentFraming = '<div class="slider-top"></div>';
								contentFraming += '<div id="sliderwrapper">';
								contentFraming += '<div id="lbutton"></div>';
								contentFraming += '<div id="slidecontainer">';
								contentFraming += '<div id="slider"></div>';
								contentFraming += '</div>';
								contentFraming += '<div id="rbutton"></div>';
								contentFraming += '</div>';
								contentFraming += '<div class="slider-btm"></div>';
								this.contentElem.set('innerHTML',contentFraming);
						},
						'tabFocusCallback': function() {
								console.log('Just got focus on the component tab....');
						},
					}
				],
*/
				loadedTabs : [],

//				cmdHandlers : {},
				cmdHandlers : {
					'hello' : {
						'cmdSubmit' : function(cmdList) {
							alert('Hello '+cmdList[0]+'!!!!');
						}
					},
					't' : {
						'cmdSubmit' : function(cmdList) {
							R8.Cmdbar.toggleTabs();
						}
					},
					'search' : {
						'cmdSubmit':function(cmdList) {
							var qList = [],numCmds = cmdList.length;

							for(i=1;i<numCmds;i++) {
								if(cmdList[i] == ' ') continue;
								var qtParts = cmdList[i].split('=');
								var param = qtParts[0],value = qtParts[1];
								var queryTerm = {'name':param,'value':value};
								qList.push(queryTerm);
							}

							switch(cmdList[0]) {
								case "node":
									var tabName = 'node-search';
									var tabI18n = 'Node Search';
									var queryTerm = 'model_name=node';
									break;
								case "component":
									var tabName = 'component-search';
									var tabI18n = 'Component Search';
									var queryTerm = 'model_name=component';
									break;
								case "blah":
									break;
							}

							if (R8.Cmdbar.tabExists(tabName)) {
//TODO: need to port all maintoolbar stuff over to tab definition
//								R8.Cmdbar.loadedTabs[tabIndex].clearContent();
								var tabIndex = R8.Cmdbar.getTabIndexByName(tabName);
								R8.Cmdbar.loadedTabs[tabIndex].clearSlider();
							} else {
								var newTab = R8.Cmdbar.cloneTabObj(this.tabDef);
								newTab.name = tabName;
								newTab['i18n'] = tabI18n;
								var tabIndex = R8.Cmdbar.addTab(newTab);
								R8.Cmdbar.registerTabEvents(tabIndex);
							}
//TODO: needed registerTabEvents seperated out from addTab b/c of some weird timing issues or something, need to revisit and hopefully consolidate
							R8.Cmdbar.changeTabFocus(tabIndex);
							if(!R8.Cmdbar.tabsPaneOpen) R8.Cmdbar.toggleTabs();

							for(term in qList) {
								if(queryTerm !='') queryTerm +='&';
								queryTerm += qList[term]['name']+'='+qList[term]['value'];
							}
							var callbacks = {
								'io:start' : R8.Cmdbar.loadedTabs[tabIndex].startSearch(),
								'io:end' : R8.Cmdbar.loadedTabs[tabIndex].endSearch(),
								'io:renderComplete' : R8.Cmdbar.loadedTabs[tabIndex].initSlider(),
							};
							R8.Ctrl.call('workspace/search',queryTerm,callbacks);
						},

						'tabDef': {
							'name':'',
							'i18n':'',
							'status':'',
							'node':null,
							'events':{},
							'contentLoader': function() {
									var name = this.name;
									var width = R8.Workspace.viewPortRegion['width'] - 65;
									var contentFraming = '<div class="slider-top"></div>';
									contentFraming += '<div id="'+name+'-slider-wrapper" class="slider-wrapper">';
									contentFraming += '<div id="lbutton"></div>';
									contentFraming += '<div id="'+name+'-list-container" class="slide-list-container" style="width: '+width+'px;">';
									contentFraming += '<div id="'+name+'-slider"></div>';
									contentFraming += '</div>';
									contentFraming += '<div id="rbutton"></div>';
									contentFraming += '</div>';
									contentFraming += '<div class="slider-btm"></div>';
//									this.contentElem.set('innerHTML',contentFraming);
									document.getElementById('cmdbar-'+this.name+'-tab-content').innerHTML = contentFraming;
//DEBUG
//console.log('Just Loaded content for tab:'+this.name);
									var nodeId = '#'+name+'-list-container';
									var resizeCallback = {
										'nodeId' : nodeId,
										'lambda' : function(height,width) {
											var width = width - 65;
											return {'width':width};
										}
									};
									R8.Workspace.addResizeCallback(resizeCallback);
							},

							'focus': function() {
								var tIndex = R8.Cmdbar.getTabIndexByName(this.name);

								YUI().use("node", function(Y) {
									R8.Cmdbar.loadedTabs[tIndex]['events']['slider_key_press'] = Y.get('document').on("keypress", function(e) {
										if (e.keyCode == 37) {
											R8.Cmdbar.loadedTabs[tIndex].slideLeft();
			//								e.halt();
										} else if(e.keyCode == 39) {
											R8.Cmdbar.loadedTabs[tIndex].slideRight();
			//								e.halt();
										}
									});
								});
							},

							'blur' : function() {
								var tIndex = R8.Cmdbar.getTabIndexByName(this.name);
//DEBUG
console.log('Blurring for:'+this.name);
console.log(R8.Cmdbar.loadedTabs[tIndex]['events']);
								if(typeof(R8.Cmdbar.loadedTabs[tIndex]['events']['slider_key_press']) != 'undefined') {
									R8.Cmdbar.loadedTabs[tIndex]['events']['slider_key_press'].detach();
								}
							},

							'clearContent':function() {},

							deleteCleanup : function() {
								var nodeId = '#'+this.name+'-list-container';
								R8.Workspace.cancelResizeCallback(nodeId);
								this.sliderAnim = null;
								this.slideBarNode = null;
							},

							//------------Search Specific Functions/Callbacks---------
							startSearch : function(ioId,arguments) {
							},
			
							endSearch : function(ioId,arguments) {
							},

							clearSlider : function() {
								if(this.slideBarNode === null) return;
console.log('Going to clear everything out...');
								this.events['slider_anim'].detach();
								delete(this.events['slider_anim']);
								this.events['lbtn_click'].detach();
								delete(this.events['lbtn_click']);
								this.events['rbtn_click'].detach();
								delete(this.events['rbtn_click']);

//TODO: figure out why slider_key_press throws undefined error after a 2nd search is run
								this.events['slider_key_press'].detach();
								delete (this.events['slider_key_press']);

								this.sliderAnim = null;
								this.slideBarNode = null;
								this.sliderSetup = false;
								document.getElementById(this.name+'-list-container').innerHTML = '';
							},

							initSlider: function() {
								var tIndex = R8.Cmdbar.getTabIndexByName(this.name);
								var tabName = this.name;
								if(document.getElementById(this.name+'-slide-bar') == null) {
									var initSliderCallback = function() { R8.Cmdbar.loadedTabs[tIndex].initSlider(); }
									setTimeout(initSliderCallback,100);
									return;
								}
//			testing();
								YUI().use('anim', function(Y){
									R8.Cmdbar.loadedTabs[tIndex].setupSliderAnim(Y,tIndex);
								});
								this.sliderSetup = true;
							},

							setupSliderAnim : function(Y,tIndex) {
								var name = R8.Cmdbar.loadedTabs[tIndex]['name'];
								R8.Cmdbar.loadedTabs[tIndex].slideBarNode = Y.one('#'+name+'-slide-bar');
								R8.Cmdbar.loadedTabs[tIndex].sliderAnim = new Y.Anim({
									node: R8.Cmdbar.loadedTabs[tIndex].slideBarNode,
									duration: 0.3,
								});
//TODO: fix bug around non uniqueness on l/r buttons for scrolling
								R8.Cmdbar.loadedTabs[tIndex]['events']['slider_anim'] = R8.Cmdbar.loadedTabs[tIndex].sliderAnim.on('end',function(){ R8.Cmdbar.loadedTabs[tIndex].sliderInMotion = false;});
								R8.Cmdbar.loadedTabs[tIndex]['events']['lbtn_click'] = Y.one('#lbutton').on('click', R8.Cmdbar.loadedTabs[tIndex].slideLeft);
								R8.Cmdbar.loadedTabs[tIndex]['events']['rbtn_click'] = Y.one('#rbutton').on('click', R8.Cmdbar.loadedTabs[tIndex].slideRight);
							},
							slideLeft : function(e) {
								var tIndex = R8.Cmdbar.getTabIndexByName(this.name);
								if(R8.Cmdbar.loadedTabs[tIndex].sliderInMotion) return;
								else R8.Cmdbar.loadedTabs[tIndex].sliderInMotion = true;
								
								R8.Cmdbar.loadedTabs[tIndex].sliderAnim.set('to', { xy: [R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getX()-510, R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getY()] });
								R8.Cmdbar.loadedTabs[tIndex].sliderAnim.run();
							},
							slideRight : function(e) {
								var tIndex = R8.Cmdbar.getTabIndexByName(this.name);
								if(R8.Cmdbar.loadedTabs[tIndex].sliderInMotion) return;
								else R8.Cmdbar.loadedTabs[tIndex].sliderInMotion = true;
								//TODO: figure out how to make the x param dynamic based on component width					
								R8.Cmdbar.loadedTabs[tIndex].sliderAnim.set('to', { xy: [R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getX()+510, R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getY()] });
								R8.Cmdbar.loadedTabs[tIndex].sliderAnim.run();
							},

							slideBarNode : null,
							sliderAnim : null,
							sliderInMotion : false,
							sliderSetup : false,
						},
						//end tabDef
					}
				}
				//end cmdHandlers
			}
		}();
	})(R8);
}
