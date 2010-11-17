if(!AvailableTools['quicksearch']) {

	AvailableTools['quicksearch'] = function(params) {
		var _name = 'quicksearch',
			_parentNodeId = params['parent_id'],
			_formId = _parentNodeId+'-'+_name+'-form',
			_formNode = null,
			_cmdInputId = _parentNodeId+'-'+_name+'-cmd',
			_cmdInputNode = null,
			_slideContainerNodeId = _parentNodeId+'-'+_name+'-list-container',
			_slideContainerNode = null,

			_sliderNodeId = _parentNodeId+'-'+_name+'-slider';
			_sliderNode = null,
			_sliderInMotion = false,
			_sliderLBtnId = _parentNodeId+'-'+_name+'-slider-lbtn',
			_sliderLBtnNode = null,
			_sliderRBtnId = _parentNodeId+'-'+_name+'-slider-rbtn',
			_sliderRBtnNode = null,
			_sliderAnim = null,

			_cmdQueue = [],
			_qIndex = null,

			_ongoingSearch = false;

		return {

			init : function() {
				_formNode = R8.Utils.Y.one('#'+_formId);
				_cmdInputNode = R8.Utils.Y.one('#'+_cmdInputId);
				_slideContainerNode = R8.Utils.Y.one('#'+_slideContainerNodeId);
				_sliderLBtnNode = R8.Utils.Y.one('#'+_sliderLBtnId);
				_sliderRBtnNode = R8.Utils.Y.one('#'+_sliderRBtnId);

//TODO: revisit, would be nice to leverage YUI eventing,but submit doesnt allow 4 return false to block form sumbmission
				var formDomNode = document.getElementById(_formId);
				var that = this;
				var onSubmit = function() {
					that.cmdSubmit(_cmdInputNode.get('value'));
					return false;
				}
				formDomNode.onsubmit = onSubmit;
//				_formNode.on('submit',onSubmit);
			},

			renderToolContent : function() {
				var content = '<div style="height: 30px; float: left;">\
							<form id="'+_formId+'">\
								<input size="30" type="text" title="Enter Command" name="'+_cmdInputId+'" id="'+_cmdInputId+'" value="">\
							</form>\
							</div>';

//				var content = '<input name="quicksearch" type="text" size="30"/>';
				return content;
			},

			renderToolBodyContent: function() {
				var bodyContent = '<div id="" style="height: 90px; width: 422px; position: relative;">\
						<div id="'+_parentNodeId+'-'+_name+'-slider-wrapper" class="slide-wrapper">\
							<div id="'+_sliderLBtnId+'" class="group-lbutton"></div>\
							<div class="slide-l-shade">\
								<div class="shade-top"></div>\
								<div class="shade-body"></div>\
								<div class="shade-bottom"></div>\
							</div>\
							<div id="'+_slideContainerNodeId+'" class="slide-container">\
								<div class="slide-container-header"></div>\
								<div id="'+_parentNodeId+'-'+_name+'-slider" style="margin-top: 10px; width: 390px;">\
									<div class="basic-item medium red-trans" style="position: relative; float: left; margin: 0 5px 0 5px;">\
										<div class="item trans">\
											<div class="l-col">\
												<div class="corner tl"></div>\
												<div class="l-col-trans-body"></div>\
												<div class="corner bl"></div>\
											</div>\
											<div class="trans-body"></div>\
											<div class="r-col">\
												<div class="corner tr"></div>\
												<div class="r-col-trans-body"></div>\
												<div class="corner br"></div>\
											</div>\
										</div>\
									</div>\
									<div class="basic-item medium red-trans" style="position: relative; float: left; margin: 0 5px 0 5px;">\
										<div class="item trans">\
											<div class="l-col">\
												<div class="corner tl"></div>\
												<div class="l-col-trans-body"></div>\
												<div class="corner bl"></div>\
											</div>\
											<div class="trans-body"></div>\
											<div class="r-col">\
												<div class="corner tr"></div>\
												<div class="r-col-trans-body"></div>\
												<div class="corner br"></div>\
											</div>\
										</div>\
									</div>\
									<div class="basic-item medium red-trans" style="position: relative; float: left; margin: 0 5px 0 5px;">\
										<div class="item trans">\
											<div class="l-col">\
												<div class="corner tl"></div>\
												<div class="l-col-trans-body"></div>\
												<div class="corner bl"></div>\
											</div>\
											<div class="trans-body"></div>\
											<div class="r-col">\
												<div class="corner tr"></div>\
												<div class="r-col-trans-body"></div>\
												<div class="corner br"></div>\
											</div>\
										</div>\
									</div>\
								</div>\
							</div>\
							<div class="slide-r-shade">\
								<div class="shade-top"></div>\
								<div class="shade-body"></div>\
								<div class="shade-bottom"></div>\
							</div>\
							<div id="'+_sliderRBtnId+'" class="group-rbutton" style=""></div>\
						</div>';

				return bodyContent;
			},

			getUserData: function() {
				//TODO:stub
			},
			toolFocus: function() {
				_cmdInputNode.focus();
			},

			focus: function() {
				
			},

			blur: function() {
				
			},

			cmdSubmit: function(cmdStr) {
				var cmd = {
					'cmd':cmdStr,
					'status':'pending',
					'parsedCmd': cmdStr.split(' '),
				}
				_cmdQueue.push(cmd);
				_cmdInputNode.set('value', '');

				var curIndex = _cmdQueue.length-1,
				_qIndex = curIndex;
				var cmdAction = _cmdQueue[curIndex]['parsedCmd'][0];
				var cmdList = [];
				var cmdLength = _cmdQueue[curIndex]['parsedCmd'].length;

				for(i=1;i<cmdLength;i++) {
					if(_cmdQueue[curIndex]['parsedCmd'][i] == ' ') continue;
					cmdList.push(_cmdQueue[curIndex]['parsedCmd'][i]);
				}

				var qList = [],numCmds = cmdList.length;

				for(i=1;i<numCmds;i++) {
					if(cmdList[i] == ' ') continue;
					var qtParts = cmdList[i].split('=');
					var param = qtParts[0],value = qtParts[1];
					var queryTerm = {'name':param,'value':value};
					qList.push(queryTerm);
				}
//TODO: i18n these strings
				switch(cmdList[0]) {
					case "node":
						var tabI18n = 'Node Search';
						var queryTerm = 'model_name=node';
						break;
					case "component":
						var tabI18n = 'Component Search';
						var queryTerm = 'model_name=component&type=template';
						break;
					case "attribute":
						var tabI18n = 'Attr Search';
						var queryTerm = 'model_name=attribute';
						break;
					case "blah":
						break;
				}
		
				this.clearSlider();

//				R8.Cmdbar.registerTabEvents(tabIndex);

		//TODO: needed registerTabEvents seperated out from addTab b/c of some weird timing issues or something, need to revisit and hopefully consolidate
//				R8.Cmdbar.changeTabFocus(tabIndex);
//				if(!R8.Cmdbar.tabsPaneOpen) R8.Cmdbar.toggleTabs();
		
				for(term in qList) {
					if(queryTerm !='') queryTerm +='&';
						queryTerm += qList[term]['name']+'='+qList[term]['value'];
				}
				queryTerm += '&panel_id='+_slideContainerNodeId+'&slider_id_prefix='+_parentNodeId+'-'+_name;
//				var tabName = this.name;
//				var renderCompleteCallback = function() {
//					R8.Cmdbar.loadedTabs[tabIndex].initSlider(R8.Cmdbar.loadedTabs[tabIndex].name);
//				}
				var that = this;
				var renderCompleteCallback = function() {
					that.initSlider();
				}
				var startCallback = function() {
					that.startSearch();
				}
				var endCallback = function() {
					that.endSearch();
				}

				var callbacks = {
					'io:start' : startCallback,
					'io:end' : endCallback,
					'io:renderComplete' : renderCompleteCallback,
				};
//console.log('Query Term:'+queryTerm);

				R8.Ctrl.call('workspace/search_2',queryTerm,callbacks);
				_cmdInputNode.blur();
			},

			startSearch: function() {
				_ongoingSearch = true;
			},
			endSearch: function() {
				_ongoingSearch = false;
			},

//------------------------------
//SLIDER RELATED
//------------------------------

			initSlider: function() {				
				if (document.getElementById(_sliderNodeId) == null) {
					var that = this;
					var initSliderCallback = function(){
						that.initSlider();
					}
					setTimeout(initSliderCallback, 50);
					return;
				}

/*				YUI().use('anim', this.setSliderAnim);
				_sliderAnim = new Y.Anim({
					node: _sliderNode,
					duration: 0.3,
				});
*/
				var that=this;
				var sliderLBtnId = _sliderLBtnId;
				YUI().use('anim', function(Y){
					that.setSliderAnim(Y);
					Y.on('click', that.slideLeft,'#'+sliderLBtnId);
				});

				_sliderAnim.on('end', function(e){
console.log('done with slider animation....');
					_sliderInMotion = false;
				},this);

//				this.setupSliderEvents();
				_sliderReady = true;
			},

			setupSliderEvents: function() {
				R8.Utils.Y.on('click', this.slideLeft,'#'+_sliderLBtnId);
//				_sliderLBtnNode.on('click', this.slideLeft);
//				_sliderRBtnNode.on('click', this.slideRight);
			},

			setSliderAnim: function(Y) {
				_sliderNode = Y.one('#' + _sliderNodeId);
				_sliderAnim = new Y.Anim({
					node: _sliderNode,
					duration: 0.3,
				});
			},

			clearSlider: function() {
				_slideContainerNode.set('innerHTML','');
			},

			slideLeft: function(e){
console.log('firing slideLeft........');
				if (_sliderInMotion) 
					return;
				else 
					_sliderInMotion = true;
					
				_sliderAnim.set('to', {
					xy: [_sliderNode.getX() - 422, _sliderNode.getY()]
				});
				_sliderAnim.run();
			},
			slideRight: function(e){
				if (_sliderInMotion) 
					return;
				else 
					_sliderInMotion = true;

				//TODO: figure out how to make the x param dynamic based on component width
				_sliderAnim.set('to', {
					xy: [_sliderNode.getX() + 422, _sliderNode.getY()]
				});
				_sliderAnim.run();
			},

		}
	};
}
