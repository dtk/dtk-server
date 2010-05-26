if(typeof R8=="undefined" || !R8) {
	var R8={};
}

if (!R8.devtools) {

	/*
	 * This is the deveveloper Tools r8 js class, more to be added
	 */
	R8.devtools = function(){
		return {
			toggleWindow: function(){
				if (R8.devtools.windowOpen == false) {
					var attributes = {
						height: {from: 32,to: 325,unit: 'px'}
					};
					R8.devtools.windowOpen = true;
				} else {
					var attributes = {
						height: {from: 325,to: 32,unit: 'px'}
					};
					R8.devtools.windowOpen = false;
				}
				var anim = new YAHOO.util.Anim('devToolsWrapper', attributes, 0.3);
				anim.animate();
				delete(anim);
			},

			timerStart: function(timerName) {
				var numTimers = R8.devtools.timers.length, 
					timerCount = 0,
					startTime = new Date().valueOf();

				if(R8.utils.isDefined(R8.devtools.timers[timerName]))
					R8.devtools.timers[timerName]["start"] = startTime;
				else
					R8.devtools.timers[timerName] = R8.devtools.getTimerObj(startTime,null);

				return;
			},

			timerStop: function(timerName) {
				var numTimers = R8.devtools.timers.length,
					stopTop = new Date().valueOf(),
					timerCount = 0;

				if(R8.utils.isUndefined(R8.devtools.timers[timerName]))
					return false;
				else
					R8.devtools.timers[timerName]["end"] = stopTime;

				return;
			},

			getElapsedTime: function(timerName) {
				var numTimers = R8.devtools.timers.length,
					timerCount = 0,
					elapsedTime = R8.devtools.timers[timerName]["end"] - R8.devtools.timers[timerName]["start"];

				if (elapsedTime >= 1000) {
					elapsedTime = elapsedTime / 1000;
					return elapsedTime + 'sec';
				} else 
					return elapsedTime + 'ms' ;
			},

			getTimerObj: function(startTime,endTime) {
				return {"start":startTime,"end":endTime};
			},

			 //this tracks if the developer tools window is open or not
			windowOpen : false,
		
			//this tracks if the devTools App has been added to the page already or not
			loaded : 1,
		
			//these arrays track timers to check code execution times
			timers : {}
		}
	}();
}