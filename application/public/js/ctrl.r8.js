
if (!R8.ctrl) {

	/*
	 * This is the controller r8 js class, more to be added
	 */
	R8.ctrl = function(){
		return {
			init : function() {
				//init goes here
			},

			//TODO: should the request handling and page updating be handled by core or R8.ctrl?
			request: function(args, successFunction) {
				if(typeof(args) === 'object')
					var params = R8.utils.json2Str(args);
				else var params = args;

				//if devToolsJs is available the app should be loaded once
				if(typeof(R8.devtools) === 'undefined')
					params += "&devToolsLoaded=0";

				if(typeof(successFunction) !== 'undefined')
					var successReturnFunction = successFunction;
				else
					var successReturnFunction = R8.ctrl.updatePage;

				YAHOO.util.Connect.asyncRequest('POST', 'index.php', {
					success: successReturnFunction,
					failure: R8.ctrl.failure
				}, params);
			},

			submitForm: function(formId, isUpload) {
				var formObj = document.getElementById(formId);

				YAHOO.util.Connect.setForm(formObj, isUpload);
				YAHOO.util.Connect.asyncRequest('POST', 'index.php', {
					upload: R8.ctrl.postUpload,
					success: R8.ctrl.updatePage,
					failure: R8.ctrl.failure
				});
			},

			updatePage: function(responseObj) {
				eval("var response =" + responseObj.responseText);

				//reset the callbacks array after execution
				R8.ctrl.tplCallbacks = new Array();

				if (R8.utils.isDefined(response['jsConfig'])) {
					R8.ctrl.setJSConfig(response['jsConfig']);
				}

				for(var i in response['ra_list']) {
					var responseItem = response['ra_list'][i];

					if (R8.utils.isDefined(response[responseItem]['cssIncludes']))
						R8.ctrl.processCSSIncludes(response[responseItem]['cssIncludes']);

					if (R8.utils.isDefined(response[responseItem]['scriptIncludes'])) {
						R8.ctrl.processScriptIncludes(response[responseItem]['scriptIncludes']);
					}
//TODO: revisit if this call should be here in this order of execution
					R8.ctrl.runJSTemplates();

					//TODO: work on framework for script handling on server side,
					//currently have addJSExeScript in ctrl and race_priority to track race conditions
					if(R8.utils.isDefined(response[responseItem]['script']) && response[responseItem]['script'] != '')
						R8.ctrl.processExeScripts(response[responseItem]['script']);

					if(!R8.utils.isUndefined(response[responseItem]['content']) && response[responseItem]['content'].length > 0)
						R8.ctrl.setResponseContent(response[responseItem]['content']);
	
					if(!R8.utils.isUndefined(response[responseItem]['data']) && response[responseItem]['data'].length > 0)
						R8.ctrl.setResponseData(response[responseItem]['data']);
	
					if (!R8.utils.isUndefined(response[responseItem]['errors']) && response[responseItem]['errors'].length > 0)
						R8.ctrl.setResponseErrors(response[responseItem]['errors']);
				}
			},

			processCSSIncludes: function(cssIncludes) {
				var cssSrc='',cssScriptElem='';

				for (var i in cssIncludes) {
					cssSrc = cssIncludes[i];

					//check to see if script has already been added to page,
					//if it hasnt, create a new DOM <script> element and append to <head>
					if (R8.ctrl.cssInCache(cssSrc) === false) {
						cssScriptElem = document.createElement('link');
						cssScriptElem.rel = "stylesheet";
						cssScriptElem.type = "text/css";
						cssScriptElem.href = cssSrc;
						document.getElementsByTagName('head')[0].appendChild(cssScriptElem);
						R8.ctrl.addCSSIncludeToCache(cssSrc);
					}
				}

			},

			processScriptIncludes: function(scriptIncludes) {

				var scriptSrc='';

				for (var i in scriptIncludes) {
					//if type=object, then its a js Tpl
					if (typeof(scriptIncludes[i]) === 'object') {
//TODO: figure out why certain action results, probably content based ones cause error with this handling
//console.log("Inside of processScriptIncludes, have an object"+scriptIncludes[i]);
						scriptSrc = scriptIncludes[i]['src'];
						R8.ctrl.addTplCallback(scriptIncludes[i]);
					}
					else {
//console.log("Inside of processScriptIncludes, no object"+scriptIncludes[i]);
						scriptSrc = scriptIncludes[i];
					}

					//check to see if script has already been added to page,
					//if it hasnt, create a new DOM <script> element and append to <head>
					if (R8.ctrl.scriptInCache(scriptSrc) === false) {
						var jsScriptElem = document.createElement('script');
						jsScriptElem.type = "text/javascript";
						jsScriptElem.src = scriptSrc;
						document.getElementById('appHeadElem').appendChild(jsScriptElem);
						R8.ctrl.addScriptIncludeToCache(scriptSrc);
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
				R8.ctrl.tplCallbacks[R8.ctrl.tplCallbacks.length] = tplInfo;
			},

			/*
			 * Add the src value for a js Include Script to the cache
			 */
			addScriptIncludeToCache: function(scriptIncludeSrc) {
				R8.ctrl.scriptIncludeCache[R8.ctrl.scriptIncludeCache.length] = scriptIncludeSrc;
			},

			/*
			 * Check to see if a js Include Script has already been added to the page
			 */
			scriptInCache: function(scriptIncludeSrc) {
				var isInCache = false, i='', cacheLength=R8.ctrl.scriptIncludeCache.length;

				for(i = 0; i < cacheLength; i++) {
					if(R8.ctrl.scriptIncludeCache[i] === scriptIncludeSrc) isInCache = true;
				}
				return isInCache;
			},

			/*
			 * Add the src value for a css Include to the cache
			 */
			addCSSIncludeToCache: function(cssIncludeSrc) {
				R8.ctrl.cssIncludeCache[R8.ctrl.cssIncludeCache.length] = cssIncludeSrc;
			},

			/*
			 * Check to see if a css Include has already been added to the page
			 */
			cssInCache: function(cssIncludeSrc) {
				var isInCache = false, i='',includeLength=R8.ctrl.cssIncludeCache.length;
				for(i = 0; i < includeLength; i++) {
					if(R8.ctrl.cssIncludeCache[i] === cssIncludeSrc) isInCache = true;
				}
				return isInCache;
			},

			runJSTemplates: function() {
				var i='',callbackLength=R8.ctrl.tplCallbacks.length;
				for(i=0; i < callbackLength; i++) {
					var jsScriptElem = document.createElement('script');
					jsScriptElem.type = "text/javascript";
					var renderType = '';

					if(R8.utils.isUndefined(R8.ctrl.tplCallbacks[i]['renderType'])) renderType = 'clear';
					else renderType = R8.ctrl.tplCallbacks[i]['renderType'];

					//eval the templateVars to make the JSON txt valid when used in the TPL
//TODO: why is the object type check needed for menu and nothing else!!!!!
//console.log("Type of templateVars:"+typeof(R8.ctrl.tplCallbacks[i]['templateVars']));
					if (typeof(R8.ctrl.tplCallbacks[i]['templateVars']) != 'object') {
//console.log("Not an object:" + R8.ctrl.tplCallbacks[i]['templateVars']);
						R8.ctrl.tplCallbacks[i]['templateVars'] = eval("(" + R8.ctrl.tplCallbacks[i]['templateVars'] + ")");
					}
					else {
console.log("Its an object:" + R8.ctrl.tplCallbacks[i]['templateVars']);
					}

					jsScriptElem.text = R8.ctrl.tplCallbacks[i]['tplCallback']+"(R8.ctrl.tplCallbacks["+i+"]['templateVars'],'"+renderType+"');";
					document.getElementById('scriptContainer').appendChild(jsScriptElem);
				}
			},

			setResponseContent: function(contentList) {
				var doc = document;
					for(i in contentList) {
						doc.getElementById(contentList[i]['panel']).innerHTML = contentList[i]['content'];
					}
			},

			setResponseData: function(dataList) {
				//TODO: add stuff here when ready
			},

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
				R8.ctrl.request(loadAppArgs);
			},

			/*
			 * This function will perform the login for a user and call amp=core&action=main
			 * @param formName		The DOM name for the login form
			 */
			doLogin: function(formName) {
				R8.ctrl.submitForm(formName,false);
			},

			/*
			 * This function will log a user out of the app an perform any cleanup necessary
			 * @param logoutArgs		A JSON object with name/value params to use for the call
			 */
			doLogout: function(logoutArgs) {
				R8.ctrl.request(logoutArgs);
			},

//TODO: not sure what this was/is doing from old code..., cleanup
			postUpload: function(o) {
				R8.ctrl.request(o.responseText.replace(/\//g, '&'));
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
			cssIncludeCache : new Array()
		}
	}();
}