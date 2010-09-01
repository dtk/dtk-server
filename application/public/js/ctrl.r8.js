
function testingjson() {
/*
	var key_query_term = document.getElementById('key_qt').value;
	var filterElem = document.getElementById('keyFilter'); 
	var key_filter = filterElem[filterElem.selectedIndex].value;
*/

	R8.Ctrl.call('component/testjsoncall');
	return;

	YUI().use('io','io-base', function(Y) {

		var cfg = {
			method: "GET",
//			data: 'key_qt='+key_query_term + '&key_filter=' + key_filter
		};

		var success = function(ioId, o) {
			if(o.responseText !== undefined) {
//				eval("var response =" + o.responseText);
				console.log(o.responseText);
//				document.getElementById('composeKeyResults').innerHTML = response.actions[0].tpl_contents;
			} else {
				console.log('respnose is undefined');
			}
		};
			var failure = function(ioId, o) {
			if(o.responseText !== undefined) {
				console.log(o.responseText);
			} else {
				console.log('respnose is undefined');
			}
		};

//		Y.on('io:start', console.log('starting io request.....'));
		Y.on('io:success', success);
		Y.on('io:failure', failure);
//		Y.on('io:end', console.log('finished io request'));
//		var request_url = base_url+'/application/compose_keys_search';
		var request_url = 'http://localhost:7000/xyz/component/testjsoncall';
		var request = Y.io(request_url, cfg);
	});
}


if(typeof(R8) === 'undefined') R8 = {}

//TODO: figure out how best to implement the template handling class
R8.Rtpl = {}

if (!R8.Ctrl) {

	/*
	 * This is the controller r8 js class, more to be added
	 */
	R8.Ctrl = function(){
		return {
			init : function() {
				//init goes here
			},

			//TODO: should the request handling and page updating be handled by core or R8.Ctrl?
			call: function(route, args, callBacks) {

				if(typeof(args) === 'object') var req_params = R8.Utils.json2Str(args);
				else if(typeof(args) === 'undefined') var req_params = ''; 
				else var req_params = args;

				//if devToolsJs is available the app should be loaded once
//				if(typeof(R8.devtools) === 'undefined')
//					params += "&devToolsLoaded=0";

				YUI().use('io','io-base', function(Y) {
					var cfg = {
						method: "POST",
						data: req_params
					};
					if (typeof(callBacks) !== 'undefined') {
						for(callback in callBacks) {
							switch(callback) {
								case "io:start":
									Y.on('io:start', callBacks[callback]);
									break;
								case "io:success":
									Y.on('io:success', callBacks[callback]);
									break;
								case "io:failure":
									Y.on('io:failure', callBacks[callback]);
									break;
								case "io:end":
									Y.on('io:end', callBacks[callback]);
									break;
								case "io:renderComplete":
									this.onRenderComplete = callBacks[callback];
									break;
							}
						}
						if(!R8.Utils.isDefined(callBacks['io:success']))
							Y.on('io:success', R8.Ctrl.updatePage);
					} else {
						Y.on('io:success', R8.Ctrl.updatePage);
					}


//TODO: revisit when config is implemented
					var request_url = 'http://localhost:7000/xyz/'+route;
					var request = Y.io(request_url, cfg);
				});

//TODO: old version of YUI, YUI3 now used, remove eventually
/*
				YAHOO.util.Connect.asyncRequest('POST', 'index.php', {
					success: successReturnFunction,
					failure: R8.Ctrl.failure
				}, params);
*/
			},

			submitForm: function(formId, isUpload) {
				var formObj = document.getElementById(formId);

				YAHOO.util.Connect.setForm(formObj, isUpload);
				YAHOO.util.Connect.asyncRequest('POST', 'index.php', {
					upload: R8.Ctrl.postUpload,
					success: R8.Ctrl.updatePage,
					failure: R8.Ctrl.failure
				});
			},

			updatePage: function(ioId, responseObj) {
				eval("R8.Ctrl.callResults[ioId] =" + responseObj.responseText);
				var response = R8.Ctrl.callResults[ioId];

				//reset the callbacks array after execution
				R8.Ctrl.tplCallbacks = new Array();

//TODO: revisit when re-implementing config handling
				if (R8.Utils.isDefined(response['config'])) {
					R8.Ctrl.setJSConfig(response['config']);
				}

				for(var i in response['as_run_list']) {
					var actionItem = response['as_run_list'][i];

					if (R8.Utils.isDefined(response[actionItem]['css_includes']))
						R8.Ctrl.processCSSIncludes(ioId);

					if (R8.Utils.isDefined(response[actionItem]['js_includes'])) {
						R8.Ctrl.processJSIncludes(ioId,actionItem);
					}

//TODO: research best practices for efficient setTimeout quick calls
					var setContentCallback = function() { R8.Ctrl.setCallContent(ioId,actionItem); }
					setTimeout(setContentCallback,20);
continue;
//TODO: revisit if this call should be here in this order of execution

//					R8.Ctrl.runJSTemplates();
//					if(!R8.Utils.isUndefined(response[responseItem]['content']) && response[responseItem]['content'].length > 0)
//						R8.Ctrl.setCallContent(response[responseItem]['content']);

					//TODO: work on framework for script handling on server side,
					//currently have addJSExeScript in ctrl and race_priority to track race conditions
					if(R8.Utils.isDefined(response[responseItem]['script']) && response[responseItem]['script'] != '')
						R8.Ctrl.processExeScripts(response[responseItem]['script']);

//TODO: this will most likely be removed after changes in response bundle
//					if(!R8.Utils.isUndefined(response[responseItem]['data']) && response[responseItem]['data'].length > 0)
//						R8.Ctrl.setResponseData(response[responseItem]['data']);

//TODO: errors not currently supported under R8 setup, need to add devtools first
//					if (!R8.Utils.isUndefined(response[responseItem]['errors']) && response[responseItem]['errors'].length > 0)
//						R8.Ctrl.setResponseErrors(response[responseItem]['errors']);
				}

			},

			processCSSIncludes: function(ioId) {
				var cssSrc='',cssScriptElem='';
				var cssIncludes = R8.Ctrl.callResults[ioId]['css_includes'];

				for (var i in cssIncludes) {
					cssSrc = cssIncludes[i];

					//check to see if script has already been added to page,
					//if it hasnt, create a new DOM <script> element and append to <head>
					if (R8.Ctrl.cssInCache(cssSrc) === false) {
						cssScriptElem = document.createElement('link');
						cssScriptElem.rel = "stylesheet";
						cssScriptElem.type = "text/css";
						cssScriptElem.href = cssSrc;
						document.getElementsByTagName('head')[0].appendChild(cssScriptElem);
						R8.Ctrl.addCSSIncludeToCache(cssSrc);
					}
				}

			},

			testing: function() {
				return 'asdfasdfaf';
			},

			processJSIncludes: function(ioId,actionName) {
				var contentList = R8.Ctrl.callResults[ioId][actionName]['content'];
				var scriptIncludes = R8.Ctrl.callResults[ioId][actionName]['js_includes'];

				for(index in contentList) {
					if(typeof(contentList[index]) === 'object' && contentList[index]['src'] != '') {
						YUI().use(function(Y) {
							var url = contentList[index]['src'];
							obj = Y.Get.script(url, {
								onSuccess: function() {
									var template_callback = contentList[index]['template_callback'];
									contentList[index]['content'] = R8.Rtpl[template_callback](contentList[index]['template_vars']);
/*
									YUI().use("json", function (Y) {
										R8.Ctrl.addScriptIncludeToCache(contentList[index]['src']);
										var template_vars_str = Y.JSON.stringify(contentList[index]['template_vars']);
										var template_callback = contentList[index]['template_callback']; 
//										R8.Ctrl.jsTplContent[template_callback] = eval(template_callback+"("+template_vars_str+");");
									});
*/
								}
							});
						});
					}
//					if(typeof(contentList[index]) === 'object' && contentList[index]['src'] != '')
//						scriptIncludes[scriptIncludes.length] = contentList[index]['src'];
				}				

				var scriptSrc='';
//TODO: revisit to determine if combo script logic should go here
				//process all included scripts
				for (var i in scriptIncludes) {
					scriptSrc = scriptIncludes[i];

					//check to see if script has already been added to page,
					//if it hasn't, create a new DOM <script> element and append to <head>
					if (R8.Ctrl.scriptInCache(scriptSrc) === false) {
						var jsScriptElem = document.createElement('script');
						jsScriptElem.type = "text/javascript";
						jsScriptElem.src = scriptSrc;
						document.getElementsByTagName('head')[0].appendChild(jsScriptElem);
						R8.Ctrl.addScriptIncludeToCache(scriptSrc);
					}
				}
			},

			processExeScripts: function(exeScripts) {
				var jsScriptElem = document.createElement('script');

				jsScriptElem.type = "text/javascript";
				for(i in exeScripts) {
					jsScriptElem.text += exeScripts[i]['content']+"\n";
				}
				document.getElementById('appHeadElem').appendChild(jsScriptElem);
			},

			addTplCallback: function(tplInfo) {
				R8.Ctrl.tplCallbacks[R8.Ctrl.tplCallbacks.length] = tplInfo;
			},

			/*
			 * Add the src value for a js Include Script to the cache
			 */
			addScriptIncludeToCache: function(scriptIncludeSrc) {
				R8.Ctrl.scriptIncludeCache[R8.Ctrl.scriptIncludeCache.length] = scriptIncludeSrc;
			},

			/*
			 * Check to see if a js Include Script has already been added to the page
			 */
			scriptInCache: function(scriptIncludeSrc) {
				var isInCache = false, i='', cacheLength=R8.Ctrl.scriptIncludeCache.length;

				for(i = 0; i < cacheLength; i++) {
					if(R8.Ctrl.scriptIncludeCache[i] === scriptIncludeSrc) isInCache = true;
				}
				return isInCache;
			},

			/*
			 * Add the src value for a css Include to the cache
			 */
			addCSSIncludeToCache: function(cssIncludeSrc) {
				R8.Ctrl.cssIncludeCache[R8.Ctrl.cssIncludeCache.length] = cssIncludeSrc;
			},

			/*
			 * Check to see if a css Include has already been added to the page
			 */
			cssInCache: function(cssIncludeSrc) {
				var isInCache = false, i='',includeLength=R8.Ctrl.cssIncludeCache.length;
				for(i = 0; i < includeLength; i++) {
					if(R8.Ctrl.cssIncludeCache[i] === cssIncludeSrc) isInCache = true;
				}
				return isInCache;
			},

			runJSTemplates: function() {
				var i='',callbackLength=R8.Ctrl.tplCallbacks.length;
				for(i=0; i < callbackLength; i++) {
					var jsScriptElem = document.createElement('script');
					jsScriptElem.type = "text/javascript";
					var renderType = '';

					if(R8.Utils.isUndefined(R8.Ctrl.tplCallbacks[i]['renderType'])) renderType = 'clear';
					else renderType = R8.Ctrl.tplCallbacks[i]['renderType'];

					//eval the templateVars to make the JSON txt valid when used in the TPL
//TODO: why is the object type check needed for menu and nothing else!!!!!
//console.log("Type of templateVars:"+typeof(R8.Ctrl.tplCallbacks[i]['templateVars']));
					if (typeof(R8.Ctrl.tplCallbacks[i]['templateVars']) != 'object') {
//console.log("Not an object:" + R8.Ctrl.tplCallbacks[i]['templateVars']);
						R8.Ctrl.tplCallbacks[i]['templateVars'] = eval("(" + R8.Ctrl.tplCallbacks[i]['templateVars'] + ")");
					}
					else {
console.log("Its an object:" + R8.Ctrl.tplCallbacks[i]['templateVars']);
					}

					jsScriptElem.text = R8.Ctrl.tplCallbacks[i]['tplCallback']+"(R8.Ctrl.tplCallbacks["+i+"]['templateVars'],'"+renderType+"');";
					document.getElementById('scriptContainer').appendChild(jsScriptElem);
				}
			},

			setContentFromJSTpl: function(contentItem) {
				var template_vars_str = '';
				YUI().use("json", function (Y) {
					var template_vars_str = Y.JSON.stringify(contentItem['template_vars']);
					var tpl_content = eval(contentItem['template_callback']+"("+template_vars_str+");");
console.log(tpl_content);
return tpl_content;
				});
			},

			callContentReady : function(ioId,actionItem) {
				var contentList = R8.Ctrl.callResults[ioId][actionItem]['content'];
				for(index in contentList) {
					if(R8.Utils.isDefined(contentList[index]['content'])) continue;
					else return false;
				}				
				R8.Ctrl.callResults[ioId]['content_ready'] = true;
				return true;
			},

			setCallContent: function(ioId,actionItem) {
				if(!R8.Ctrl.callContentReady(ioId,actionItem)) {
					var setContentCallback = function() { R8.Ctrl.setCallContent(ioId,actionItem); }
					setTimeout(setContentCallback,20);
					return;
				}

				var contentList = R8.Ctrl.callResults[ioId][actionItem]['content'];
				var doc = document;
				var panelsContent = {};
//console.log(contentList);
				for(i in contentList) {
					if(R8.Utils.isDefined(contentList[i]['content'])) 
						var content = contentList[i]['content'];
					else {
//						var content = R8.Ctrl.getContentJSTpl(contentList[i]);
						var content = 'crap';
						var template_callback = contentList[i]['template_callback'];
//						var content = R8.Ctrl.jsTplContent[template_callback];
//						while(typeof(content) === 'undefined') {
//							content = R8.Ctrl.jsTplContent[template_callback];
//						}
					}

					var panel = contentList[i]['panel'];
					var assign_type = contentList[i]['assign_type'];

					switch(assign_type) {
						case "append":
							if(!R8.Utils.isDefined(panelsContent[panel])) {
								panelsContent[panel] = content;
							} else {
								panelsContent[panel] += content;
							}
							break;
						case "replace":
							panelsContent[panel] = content;
							break;
						case "prepend":
							if(!R8.Utils.isDefined(panels_content[panel])) {
								panelsContent[panel] = content
							} else {
								tmp_contents = panelsContent[panel]
								panelsContent[panel] = content + tmp_contents
							}
							break;
					}
				}
				for(panel in panelsContent) {
					doc.getElementById(panel).innerHTML = panelsContent[panel];
				}
				if(this.onRenderComplete != null) {
					this.onRenderComplete();
					this.onRenderComplete = null;
				}
			},

//TODO: probably remove this, doesnt look like it will be used with new style rendering
//			setResponseData: function(dataList) {
				//TODO: add stuff here when ready
//			},

			//TODO: fine tune error handling, have some scenarios
			//	1) Collect 1 or more errors and append to a panel (login example)
			//	2) Collect 1 or more errors and render generic error dialog/panel
			//	3) Alert to user with 1 or more errors
			//	etc
			setResponseErrors: function(errorList) {
					var errorTxt = '', errorPanels = [], i='', panel='', doc = document;

					//TODO: maybe pass this off to some js styler, dont like html being in here
					//collect and sort all error msg's into errorPanels array

					for(i in errorList) {
						if(typeof(errorPanels[errorList[i]['panel']]) === 'undefined')
							errorPanels[errorList[i]['panel']] = [];
	
						errorPanels[errorList[i]['panel']][errorPanels[errorList[i]['panel']].length] = errorList[i]['error'];
					}

					//now interate through errorPanels and render to screen
					for(panel in errorPanels) {
						var errorTxt = '';
						for(k in errorPanels[panel]) {
							errorTxt += errorPanels[panel][k]+'<br/>';
						}
						doc.getElementById(panel).innerHTML = errorTxt;
					}
			},

			/*
			 * This function will load the initial framework of the application
			 * @param appLoadArgs		A JSON object with name/value params to use for the call
			 */
			loadApp: function(loadAppArgs) {
				R8.Ctrl.request(loadAppArgs);
			},

			/*
			 * This function will perform the login for a user and call amp=core&action=main
			 * @param formName		The DOM name for the login form
			 */
			doLogin: function(formName) {
				R8.Ctrl.submitForm(formName,false);
			},

			/*
			 * This function will log a user out of the app an perform any cleanup necessary
			 * @param logoutArgs		A JSON object with name/value params to use for the call
			 */
			doLogout: function(logoutArgs) {
				R8.Ctrl.request(logoutArgs);
			},

//TODO: not sure what this was/is doing from old code..., cleanup
			postUpload: function(o) {
				R8.Ctrl.request(o.responseText.replace(/\//g, '&'));
			},

			failure: function(o) {
				console.log(o);
			},

			notify: function(msg) {
				alert(msg);
			},

			setJSConfig: function(configParams) {
				for (cfgName in configParams) {
					R8.config[cfgName] = configParams[cfgName];
				}
			},

			/*
			 * This is used to loop through possible templates at the end of a request,
			 * it will be used to call all tpl js functions to render their appropriate content
			 */
			tplCallbacks : new Array(),
	
			/*
			 * This is used to track which js scripts have been added to the page so redundant adds dont happen
			 */
			scriptIncludeCache : new Array(),
		
			/*
			 * This is used to track which css files have been added to the page so redundant adds dont happen
			 */
			cssIncludeCache : new Array(),

			/*
			 * This stores all the content by panel from the call response
			 */
			callResults : {},

			jsTplContent : {},
			onRenderComplete : null,
		}
	}();
}