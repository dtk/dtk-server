
if (!R8.Workspace) {

	/*
	 * This is the utility r8 js class, more to be added
	 */
	R8.Workspace = function(){
		return {

			//DOM element reference for workspace container DIV
			workspaceElem : null,

			//Y Node reference Object for the workspaceElem
			nodeRef : null,

			/*
			 * Load a given workspace or create a new empty one
			 * @method loadWorkspace
			 * @param {string} wSpaceID ID corresponding to a given workspace to load, if empty/null create empty space
			 */
			loadWorkspace: function(wSpaceID){
				this.workspaceElem = document.getElementById('mainWorkspace');

				this.nodeRef = R8.Utils.Y.one(this.workspaceElem);
				R8.Utils.Y.delegate('click',this.updateSelectedElements,this.nodeRef,'.component, .connector');
				R8.Utils.Y.delegate('click',this.clearSelectedElements,'body','#mainWorkspace');
				R8.Utils.Y.delegate('mousedown',this.checkMouseDownEvent,'body','#mainWorkspace');

//TODO: right now hardcoding assignment from demoData.r8.js
				this.components = workspaceComponents;
				this.ports = workspacePorts;

//TODO: add logic in to retrieve workspace info based on ID
				for(var c in this.components) {
					var comp = R8.Component.render(this.components[c]);
					this.workspaceElem.appendChild(comp);
					this.addDragDrop(comp);
					R8.Component.renderPorts(comp);

/*
					for (var i in this.components[c].availPorts[p]) {
						var portObj = this.components[c].availPorts[p][i];
						var portElemID = c + '-' + p + '-' + portObj.id;
						this.ports[portElemID] = portObj;
console.log('registering port:'+portElemID);
					}
*/
//TODO: this might change with behavior change of Delegate to query all children, not just 1st level
					this.registerPorts(c);
				}

				for(var c in this.components) {
//TODO: cleanup after reworking server/client side def and store
//*****TODO: rework and FLATTEN how ports are stored under components, should be completely flat
					for(var p in this.components[c].availPorts) {
					}

				}

//TODO: render all connectors on page after rendering components/nodes/groups, etc
				this.connectors = workspaceConnectors;
/*
				for(var c in this.connectors) {
					var startElemID = this.connectors[c].startElement.connectElemID;
					var endElemID = this.connectors[c].endElements[0].connectElemID;
					var connectionType = this.connectors[c].type;
					R8.Canvas.renderConnector(c);
				}
*/
			},

			activeTool : 'selection',
			selectionDragEvent : null,
			selectionMouseUpEvent : null,
			selectionStartX : 0,
			selectionStartY : 0,
			selectionBoxElem : null,
			checkMouseDownEvent : function(e) {
				if(R8.Workspace.activeTool === 'selection') {
					R8.Workspace.selectionStartX = e.pageX;
					R8.Workspace.selectionStartY = e.pageY;
					R8.Workspace.selectionDragEvent = R8.Utils.Y.one('#mainWorkspace').on('mousemove', R8.Workspace.updateSelectionRegion);
					R8.Workspace.selectionMouseUpEvent = R8.Utils.Y.one('#mainWorkspace').on('mouseup', R8.Workspace.handleSelectionMouseUp);
				}
			},

			updateSelectionRegion : function(e) {
				var boxHeight = Math.sqrt(Math.pow((e.pageY-R8.Workspace.selectionStartY),2));
				var boxWidth = Math.sqrt(Math.pow((e.pageX-R8.Workspace.selectionStartX),2));
				var mouseX = e.pageX;
				var mouseY = e.pageY;
				var boxStyles = {'height':boxHeight+'px','width':boxWidth+'px'};

				if(R8.Workspace.selectionBoxElem === null) {
					R8.Workspace.selectionBoxElem = document.createElement('div');
					R8.Workspace.selectionBoxElem.setAttribute('class','selectionBox');
					R8.Workspace.selectionBoxElem.setAttribute('id','selectionBox');
					R8.Workspace.workspaceElem.appendChild(R8.Workspace.selectionBoxElem);
				}

				if(mouseX < R8.Workspace.selectionStartX)
					boxStyles['left'] = mouseX + 'px';
				else
					boxStyles['left'] = R8.Workspace.selectionStartX + 'px';

				if(mouseY < R8.Workspace.selectionStartY)
					boxStyles['top'] = mouseY + 'px';
				else
					boxStyles['top'] = R8.Workspace.selectionStartY + 'px';

				R8.Utils.Y.one(R8.Workspace.selectionBoxElem).setStyles(boxStyles);
			},
			handleSelectionMouseUp : function(e) {
				R8.Workspace.selectionDragEvent.detach();
				R8.Workspace.selectionMouseUpEvent.detach();
				if (R8.Workspace.selectionBoxElem) {
					R8.Workspace.workspaceElem.removeChild(R8.Workspace.selectionBoxElem);
					R8.Workspace.selectionBoxElem = null;
				}
			},

			/*
			 * addDragDrop will make a component drag/droppable on a workspace
			 * @method addDragDrop
			 * @param {string} 	componentID The DOM ID for the component to add drag drop capabilities to
			 * @param {DOM Elem}	Node Object to add drag drop capabilities to
			 */
			addDragDrop : function() {
				var a = arguments;
				if(typeof(a[0]) === 'object') {
					var compNode = R8.Utils.Y.one(a[0]);
					var compID = compNode.get('id');
				} else if(typeof(a[0]) === 'string') {
					var compID = a[0];
					var compNode = R8.Utils.Y.one('#'+compID);
				}

				//Selector of the node to make draggable
//				compNode.on('mousedown', this.updateClickFocus,compNode);

				var dd = new R8.Utils.Y.DD.Drag({
					node: '#'+compID,
				});
				dd.on('drag:start',function(){
					R8.Workspace.clearSelectedElements();
					R8.Utils.Y.one('#'+compID).addClass('compFocus');
					R8.Workspace.selectedElements[compID] = R8.Workspace.components[compID];
				});
				dd.on('drag:drag',function(){
					R8.Component.refreshConnectors(this.get('node').get('id'));
				});

				//add the dd object to the page components list
				this.components[compID].ddObj = dd;
			},

			/*
			 * removeDragDrop will take away a components drag/droppable capabilites on a workspace
			 * @method removeDragDrop
			 * @param {string} 	componentID The DOM ID for the component to remove drag drop capabilities from
			 * @param {Node}	Node Object to remove drag drop capabilities from
			 */
			removeDragDrop: function(componentID){
			},

			/*
			 * Add an item to the workspace (component,connector,etc)
			 */
			add : function() {
				//stuff to be added here
			},

			updateSelectedElements : function(e) {
				if(typeof(R8.Workspace.components[e.currentTarget.get('id')]) === 'undefined') {
					R8.Workspace.clearSelectedElements();
					return;
				} else {
					//if ctrl no held then clear all currently selected
					if(e.ctrlKey == false) R8.Workspace.clearSelectedElements();
					R8.Workspace.selectedElements[e.currentTarget.get('id')] = R8.Workspace.components[e.currentTarget.get('id')];
					var tempObj = R8.Utils.Y.one('#'+e.currentTarget.get('id'));
					tempObj.addClass('compFocus');
					e.stopImmediatePropagation();
				}
				return;
			},

			/*
			 * clearSelectedElements removes styling from any selectedElements
			 * @method clearSelectedElements
			 * @param {Evt} e Event object passed from event firing
			 * @param {String} clickEventTarget String indicating if being called from which workspace event
			 */
			clearSelectedElements : function() {
				for(var elemID in R8.Workspace.selectedElements) {
					R8.Utils.Y.one('#'+R8.Workspace.selectedElements[elemID].id).removeClass('compFocus');
				}
				R8.Workspace.selectedElements = {};
			},

			/*
			 * registerPorts will register ports with workspace and activate for connection if applicable
			 * @method registerPorts
			 * @param {string} compElemID
			 */
			registerPorts : function(compElemID) {
//				var portObj = R8.Workspace.ports[portElemID];

//TODO: figure out how to handle groups for drop zones
				var groups = ['test'];

				var dragDelegate = new R8.Utils.Y.DD.Delegate({
						cont:'#'+compElemID,
						nodes:'.available',
						groups: groups
						}
					);
				dragDelegate.dd.plug(R8.Utils.Y.Plugin.DDProxy, {
					borderStyle: false,
					moveOnEnd: false
				});
				dragDelegate.on('drag:start', function(e) {
					e.stopPropagation();
					var p = this.get('dragNode'),
						n = this.get('currentNode');
					p.setAttribute('class', n.getAttribute('class'));
					this.dd.addToGroup(groups);

					var drop = new R8.Utils.Y.DD.Drop({
						node: '#comp1-north-0',
						groups: groups
					});

				});
				dragDelegate.on('drag:drag', function(e) {
					e.stopPropagation();
					R8.Canvas.renderDragWire(this.get('currentNode'),this.get('dragNode'));
				});
				dragDelegate.on('drag:drophit', function(e) {
//					wireConnected = true;
					var wireCanvas = R8.Utils.Y.one('#wireCanvas');
					R8.Utils.Y.one('#mainWorkspace').removeChild(wireCanvas);
					delete(wireCanvas);
					R8.Workspace.createConnector(this.get('currentNode').get('id'),e.drop.get('node').get('id'));
//					console.log('Gyeah!! Hit Target Yo!');
				});

				dragDelegate.on('drag:dropmiss', function(e) {
					var wireCanvas = R8.Utils.Y.one('#wireCanvas');
					R8.Utils.Y.one('#mainWorkspace').removeChild(wireCanvas);
					delete(wireCanvas);
					console.log('drop miss');
				});
			},

			/*
			 * createConnector will create details for new connector, render it and call the server to persist it
			 * @method createConnector
			 */
			createConnector : function(startElemID,endElemID) {
				var startConnectorLocation = R8.Workspace.ports[startElemID].location;
				var startCompID = R8.Workspace.ports[startElemID].compID;
				var endConnectorLocation = R8.Workspace.ports[endElemID].location;
				var endCompID = R8.Workspace.ports[endElemID].compID;
				var connectorType = 'fullBezier';
				var date = new Date();
				var tempConnectorID = 't-'+date.getTime() + '-' + Math.floor(Math.random()*20);

				R8.Workspace.connectors[tempConnectorID] = {
					'type': connectorType,
					'startElement': {
						'elemID': '?',
						'location':startConnectorLocation,
						'connectElemID':startElemID
					},
					'endElements': [{
						'elemID':'?',
						'location':endConnectorLocation,
						'connectElemID':endElemID
					}]
				};

				R8.Canvas.renderConnector(tempConnectorID);

				var startNode = R8.Utils.Y.one('#'+startElemID);
				var endNode = R8.Utils.Y.one('#'+endElemID);
				startNode.removeClass('available');
				startNode.addClass('connected');
				endNode.removeClass('available');
				endNode.addClass('connected');

//TODO: add call to server here to persist, then update tempConnectorID with actual persisted ID
				R8.Workspace.components[startCompID].connectors[tempConnectorID] = R8.Workspace.connectors[tempConnectorID];
				R8.Workspace.components[endCompID].connectors[tempConnectorID] = R8.Workspace.connectors[tempConnectorID];
			},

			/*
			 * Collection of active connectors for the given workspace
			 */
			connectors: {},

			/*
			 * Collection of active ports in given workspace
			 */
			ports: {},
			
			/*
			 * Collection of active elements for the given workspace
			 */
			components: {},

			/*
			 * Collection of selected/focused elements for the given workspace
			 */
			selectedElements : {}
		}
	}();
}