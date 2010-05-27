if(typeof(R8)=="undefined" || !R8) {
	var R8= new R8();
}

if (!R8.Toolbar) {

	R8.Toolbar = function() {
		return {
			toggleSlider : function(){
				$("#sliderbar").slideToggle(100);
			}
		}
	}();
}
