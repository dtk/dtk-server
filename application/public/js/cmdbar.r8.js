 
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

					var tabHolder = document.getElementById('cmdbar-tabs');
					tabHolder.innerHTML += tabHTML;
					var tabContainer = document.getElementById('cmdbar-tab-content-wrapper');

//					var tabContentsHTML = '<div id="cmdbar-'+tab['name']+'-tab-content" style="height: 300px; width: 100%"></div>';
					if (typeof(tab['contentCallback']) === 'undefined') {
						var tabContentsHTML = '<div id="cmdbar-' + tab['name'] + '-tab-content" style="height: 100px; width: 100%; display:none;"></div>';
						tabContainer.innerHTML += tabContentsHTML;
					} else {
						tab['contentCallback']();
					}
					var newTabIndex = numTabs;
					this.loadedTabs[newTabIndex] = tab;
					this.loadedTabs[newTabIndex]['contentElem'] = R8.Utils.Y.one('#cmdbar-'+R8.Cmdbar.loadedTabs[newTabIndex]['name']+'-tab-content');
					if(typeof(this.loadedTabs[newTabIndex]['contentLoader']) !='undefined') {
						this.loadedTabs[newTabIndex]['contentLoader']();
					}

					return newTabIndex;
				},

				registerTabEvents : function(i) {
					YUI().use('node','event',function(Y){
						//process the tab element and related events
						R8.Cmdbar.loadedTabs[i]['elem'] = Y.one('#cmdbar-'+R8.Cmdbar.loadedTabs[i]['name']+'-tab');
						R8.Cmdbar.loadedTabs[i]['events']['tabClick'] = R8.Cmdbar.loadedTabs[i]['elem'].on('click',function(e){
							R8.Cmdbar.changeTabFocus(e.currentTarget.getAttribute('data-tabindex'));
						});

						//process the close region element and related events
						R8.Cmdbar.loadedTabs[i]['closeElem'] = Y.one('#cmdbar-'+R8.Cmdbar.loadedTabs[i]['name']+'-tab-close');
						R8.Cmdbar.loadedTabs[i]['events']['closeMoEvent'] = R8.Cmdbar.loadedTabs[i]['closeElem'].on('mouseover', function(e){
							e.currentTarget.addClass('hover');
						});
						R8.Cmdbar.loadedTabs[i]['events']['closeMlEvent'] = R8.Cmdbar.loadedTabs[i]['closeElem'].on('mouseleave', function(e){
							e.currentTarget.removeClass('hover');
						});
						R8.Cmdbar.loadedTabs[i]['events']['closeClickEvent'] = R8.Cmdbar.loadedTabs[i]['closeElem'].on('click', function(e){ 
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
							R8.Cmdbar.deleteTabs(tabIndex);
							e.halt();
						});
					});
				},

				changeTabFocus : function(index) {
//					if(R8.Cmdbar.isTabFocused(index)) return true;

					var zIndex = 509;
					var tabList = R8.Cmdbar.loadedTabs;
					for(tab in tabList) {
						if(tab == index) {
							tabList[tab]['elem'].addClass('active');
							tabList[tab]['elem'].setStyles({'zIndex': 510});
							tabList[tab]['status'] = 'active';
//TODO:revisit, temp hack b/c it only seems to work on last tab element
//							tabList[tab]['contentElem'].setStyles({'display': 'block'});
							document.getElementById('cmdbar-'+tabList[tab]['name']+'-tab-content').style.display='block';
						} else {
							tabList[tab]['elem'].removeClass('active');
							tabList[tab]['status'] = '';
							tabList[tab]['elem'].setStyles({'zIndex': zIndex});
//							tabList[tab]['contentElem'].setStyle({'display':'none'});
							document.getElementById('cmdbar-'+tabList[tab]['name']+'-tab-content').style.display='none';
							zIndex--;
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
						this.cmdHandlers[cmdAction].actionSubmit(cmdList);
					}
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
					'elem' : null,
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
						'elem':null,
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
						'elem':null,
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
						'elem':null,
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
					'search' : {
						'actionSubmit':function(cmdList) {
							var qList = [],numCmds = cmdList.length;
//console.log(cmdList);
							for(i=1;i<numCmds;i++) {
								if(cmdList[i] == ' ') continue;
								var qtParts = cmdList[i].split('=');
								var param = qtParts[0],value = qtParts[1];
								var queryTerm = {'name':param,'value':value};
								qList.push(queryTerm);
							}

							switch(cmdList[0]) {
								case "node":
									this.tabDef['name'] = 'node-search';
									this.tabDef['i18n'] = 'Node Search';
									break;
								case "component":
									break;
								case "blah":
									break;
							}

							if (R8.Cmdbar.tabExists(this.tabDef['name'])) {
//TODO: need to port all maintoolbar stuff over to tab definition
//								R8.Cmdbar.loadedTabs[tabIndex].clearContent();
								var tabIndex = R8.Cmdbar.getTabIndexByName(this.tabDef['name']);
								R8.MainToolbar.clearSlider();
							} else {
								var tabIndex = R8.Cmdbar.addTab(this.tabDef);
								R8.Cmdbar.registerTabEvents(tabIndex);
							}
//TODO: needed registerTabEvents seperated out from addTab b/c of some weird timing issues or something, need to revisit and hopefully consolidate
							R8.Cmdbar.changeTabFocus(tabIndex);
							if(!R8.Cmdbar.tabsPaneOpen) R8.Cmdbar.toggleTabs();

							var queryTerm = '';
							for(term in qList) {
								if(queryTerm !='') queryTerm +='&';
								queryTerm += qList[term]['name']+'='+qList[term]['value'];
							}
							var callbacks = {
								'io:start':R8.MainToolbar.startSearch(),
								'io:end':R8.MainToolbar.endSearch(),
								'io:renderComplete':R8.MainToolbar.initSlider(),
							};
							R8.Ctrl.call('workspace/search',queryTerm,callbacks);
						},

						'tabDef': {
							'name':'search',
							'i18n':'',
							'status':'',
							'elem':null,
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
							'clearContent':function() {}
						},
						//end tabDef
					}
				}
				//end cmdHandlers
			}
		}();
	})(R8);
}
