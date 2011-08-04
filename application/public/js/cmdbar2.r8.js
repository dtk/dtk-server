
if (!R8.Cmdbar2) {

		R8.Cmdbar2 = function(params) {
//DEBUG
//console.log('inside of cmdbar2 create...');
//console.log(params);

			var _containerNode = params.containerNode,
				_panel = params.panel,
				_parentView = params.viewSpace,
				_viewSpace = params.viewSpace;

			return {
				init: function() {
					this.setupTabs();
					this.setupCmdLine();

					this.cmdHandlers['search'] = R8.Commands.search;
				},
				get: function(key) {
					switch(key) {
						case "containerNode":
							return _containerNode;
							break;
						case "viewSpace":
							return _viewSpace;
							break;
						case "parentView":
							return _parentView;
							break;
					}
				},
				setupTabs: function() {
					for(i in this.tabs) {
						this.addTab(this.tabs[i]);
					}
//TODO: dont know why, might be rendering/timing issue, but had to make seperate loop to register events
//else, only the last tab was getting fully setup
					for (i in this.loadedTabs) {
//						R8.Cmdbar.registerTabEvents(i);
						this.registerTabEvents(i);
					}
				},
				addTab: function(tab) {
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
						this.loadedTabs[newTabIndex]['contentLoader'](_containerNode);
					}
//					this.loadedTabs[newTabIndex]['node'] = R8.Utils.Y.one('#cmdbar-'+R8.Cmdbar.loadedTabs[newTabIndex]['name']+'-tab');

					return newTabIndex;
				},

				cloneTabObj : function(o) {
					if(typeof(o) != 'object') return o;
					if(o == null) return o;

					var newO = new Object();

//					for(var i in o) newO[i] = R8.Cmdbar.cloneTabObj(o[i]);
					for(var i in o) newO[i] = this.cloneTabObj(o[i]);
					return newO;
				},

				registerTabEvents : function(i) {
					var that=this;
					YUI().use('node','event',function(Y){
						//process the tab element and related events
						that.loadedTabs[i]['contentElem'] = Y.one('#cmdbar-'+that.loadedTabs[i]['name']+'-tab-content');
						that.loadedTabs[i]['node'] = Y.one('#cmdbar-'+that.loadedTabs[i]['name']+'-tab');

						that.loadedTabs[i]['events']['tabClick'] = that.loadedTabs[i]['node'].on('click',function(e){
							e.halt();
							this.changeTabFocus(e.currentTarget.getAttribute('data-tabindex'));
						},that);

						//process the close region element and related events
						that.loadedTabs[i]['closeElem'] = Y.one('#cmdbar-'+that.loadedTabs[i]['name']+'-tab-close');
						that.loadedTabs[i]['events']['closeMoEvent'] = that.loadedTabs[i]['closeElem'].on('mouseover', function(e){
							e.halt();
							e.currentTarget.addClass('hover');
						});
						that.loadedTabs[i]['events']['closeMlEvent'] = that.loadedTabs[i]['closeElem'].on('mouseleave', function(e){
							e.halt();
							e.currentTarget.removeClass('hover');
						});
						that.loadedTabs[i]['events']['closeClickEvent'] = that.loadedTabs[i]['closeElem'].on('click', function(e){ 
							e.halt();
							var tabIndex = e.currentTarget.getAttribute('data-tabindex');
							var tabName = this.loadedTabs[tabIndex]['name'];
							var tabContainerElem = document.getElementById('cmdbar-tab-content-wrapper');
							var tabContentElem = document.getElementById('cmdbar-'+tabName+'-tab-content');
							tabContainerElem.removeChild(tabContentElem);

							var cmdbarTabsElem = document.getElementById('cmdbar-tabs');
							var tabElem = document.getElementById('cmdbar-'+tabName+'-tab');
							cmdbarTabsElem.removeChild(tabElem);

							//clean up all event handlers
							for(event in this.loadedTabs[tabIndex]['events']) {
								this.loadedTabs[tabIndex]['events'][event].detach();
								delete(this.loadedTabs[tabIndex]['events'][event]);
							}
							this.loadedTabs[tabIndex]['deleteCleanup']();
							this.deleteTabs(tabIndex);
							if(this.loadedTabs.length == 1) {
								this.changeTabFocus(0);
							}
						},that);
					});
				},

				changeTabFocus : function(index) {
					var zIndex = 509;

					for(tab in this.loadedTabs) {
						if(tab == index) {
							this.loadedTabs[tab]['node'].addClass('active');
							this.loadedTabs[tab]['node'].setStyles({'zIndex': 510});
							this.loadedTabs[tab]['status'] = 'active';
							this.loadedTabs[tab]['contentElem'].setStyle('display','block');

							if(this.loadedTabs.length == 1)
								this.loadedTabs[tab]['node'].removeClass('not-first');

							this.loadedTabs[tab].focus(this);
						} else {
							this.loadedTabs[tab]['node'].removeClass('active');
							this.loadedTabs[tab]['status'] = '';
							this.loadedTabs[tab]['node'].setStyles({'zIndex': zIndex});
							this.loadedTabs[tab]['contentElem'].setStyle('display','none');
							zIndex--;
							this.loadedTabs[tab].blur(this);
						}
					}
				},

				toggleTabs : function() {
					R8.Utils.$("#cmdbar-tab-content-wrapper").slideToggle(250);
					if(this.tabsPaneOpen) this.tabsPaneOpen = false;
					else this.tabsPaneOpen = true;
/*
					var tabs_display = document.getElementById('cmdbar-tab-content-wrapper').style.display;
					if(tabs_display.toLowerCase() == 'block') R8.Cmdbar.tabsPaneOpen = true;
					else R8.Cmdbar.tabsPaneOpen = false;
*/
				},

				isTabFocused : function(index) {
					index = parseInt(index);
					if(this.loadedTabs[index]['status'] == 'active') return true;
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

					var rest = this.loadedTabs.slice((to || from) + 1 || this.loadedTabs.length);
					this.loadedTabs.length = from < 0 ? this.loadedTabs.length + from : from;
					this.loadedTabs.push.apply(this.loadedTabs, rest);
					this.updateTabIndexes();

					if(this.loadedTabs.length == 0 && this.tabsPaneOpen) this.toggleTabs();
				},

				updateTabIndexes : function() {
					for(i in this.loadedTabs) {
						var tabName = this.loadedTabs[i]['name'];
						var tabElem = R8.Utils.Y.one('#cmdbar-'+tabName+'-tab');
						tabElem.setAttribute('data-tabindex',i);
						var tabCloseElem = R8.Utils.Y.one('#cmdbar-'+tabName+'-tab-close');
						tabCloseElem.setAttribute('data-tabindex',i);
					}
				},

				setupCmdLine : function() {
					this.cmdr['node'] = R8.Utils.Y.one('#'+_parentView.get('id')+'-cmd');
					var _this=this;
					YUI().use('node','event',function(Y){
						_this['cmdr']['events']['keyEntry'] = _this['cmdr']['node'].on('keypress',function(e){
//DEBUG
//console.log(e.charCode);

							//arrow up
							if(e.charCode == 38) {
								e.halt();
								var index = _this.cmdr['qIndex'];
								if (index == 0) {
									_this.cmdr['qIndex'] = 0;
									var prevCmd = _this.cmdr['queue'][0]['cmd'];
									_this.cmdr['node'].set('value',prevCmd);
									return;
								}

								var prevCmd = _this.cmdr['queue'][index]['cmd'];
								_this.cmdr['node'].set('value',prevCmd);
								_this.cmdr['qIndex'] = (index-1);
							}
							//arrow down
							else if(e.charCode == 40) {
								e.halt();
								var index = _this.cmdr['qIndex'];
								var qMax = _this.cmdr['queue'].length-1;
								if (index == qMax) {
									_this.cmdr['qIndex'] = qMax;
									_this.cmdr['node'].set('value','');
									return;
								}
								var nextIndex = index+1;
								_this.cmdr['qIndex'] = nextIndex;

								var nextCmd = this.cmdr['queue'][nextIndex]['cmd'];
								_this.cmdr['node'].set('value',nextCmd);
							}
							//enter
							else if(e.charCode == 13) {
								e.halt();
								_this.submit();
							}
						},_this);
					});
				},

				submit: function() {
					var cmdStr = this.cmdr['node'].get('value');

//DEBUG
//console.log('submitting cmdbar:'+cmdStr);

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
						return false;
					} else {
						var cmdList = [];
						var cmdLength = this.cmdr['queue'][curIndex]['parsedCmd'].length;
						for(i=1;i<cmdLength;i++) {
							if(this.cmdr['queue'][curIndex]['parsedCmd'][i] == ' ') continue;
							cmdList.push(this.cmdr['queue'][curIndex]['parsedCmd'][i]);
						}

						this.cmdHandlers[cmdAction].cmdSubmit(cmdList,this);
					}
				},

				cmdr : {
					'node' : null,
					'queue' : [],
					'qIndex' : 0,
					'events': {},
				},

				tabExists : function(tabName) {
					for(i in this.loadedTabs) {
						if(this.loadedTabs[i]['name'] == tabName) return true;
					}
					return false;					
				},

				getTabIndexByName : function(tabName) {
					for(i in this.loadedTabs) {
						if(this.loadedTabs[i]['name'] == tabName) return i;
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
					'ricardo' : {
						cmdSubmit : function(cmdList) {

							var newvalue = cmdList[0] + 10;
							alert(newvalue);
						}
					},
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
					'toggle' : {
						'cmdSubmit' : function(cmdList) {
							R8.Cmdbar.toggleTabs();
						}
					},
				}
				//end cmdHandlers
			}
		};
}
