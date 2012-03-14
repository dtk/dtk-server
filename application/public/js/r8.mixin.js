
if(!R8.mixin) {
	var _mAvailable = {
		'mixin': 'mixin'
	};
	R8.mixin = function(obj,mixin) {
		var _mixer = new R8[mixin];

		for(var f in _mixer) {
			obj[f] = _mixer[f]
		}
		return obj;
	};
}

if(!R8.event) {

	R8.event = function() {
		var _eventCallbacks = {};

		return {
			purgeEvent: function(eventName,id) {
				if(typeof(_eventCallbacks[eventName]) == 'undefined') return;

				for(var i in _eventCallbacks[eventName]) {
					var eventObj = _eventCallbacks[eventName][i];
					if(eventObj.id == id) {
						R8.Utils.arrayRemove(_eventCallbacks[eventName],i);
					}
				}
			},
			clearEvent: function(eventName) {
				delete(_eventCallbacks[eventName]);
			},
			on: function(eventName,callback,scope) {
				if(typeof(_eventCallbacks[eventName]) == 'undefined') _eventCallbacks[eventName] = [];

				var eventObj = {
					'id': R8.Utils.Y.guid(),
					'callback': callback,
					'scope': scope
				}
				_eventCallbacks[eventName].push(eventObj);

				var _this = this;
				var retObj = {
					'id': eventObj.id,
					'eventName': eventName,
					'detach': function() {
						_this.purgeEvent(this.eventName,this.id)
					}
				}
			},
			fire: function(eventName,eventObj) {
//DEBUG
//console.log('going to fire  event:'+eventName+' with params:');
//console.log(eventObj);
//console.log('-------------------');
				for(var i in _eventCallbacks[eventName]) {
					var callbackObj = _eventCallbacks[eventName][i];
					if(typeof(callbackObj.scope) != 'undefined') {
						callbackObj.callback.call(callbackObj.scope,eventObj);
					}
				}
			}			
		}
	}
}
